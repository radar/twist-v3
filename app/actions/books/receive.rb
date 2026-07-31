# frozen_string_literal: true

require "openssl"
require "rack/constants"

module Twist
  module Actions
    module Books
      class Receive < Twist::Action
        include Deps[receive_book: "operations.books.receive"]
        include Deps[find_book: "operations.books.find"]

        GITHUB_EVENT_HEADER = "HTTP_X_GITHUB_EVENT"

        # GitHub signs the raw request body with HMAC-SHA256 when the webhook has
        # a secret, and sends the result as `X-Hub-Signature-256: sha256=<hex>`.
        # The legacy SHA-1 `X-Hub-Signature` header is deliberately ignored.
        SIGNATURE_HEADER = "HTTP_X_HUB_SIGNATURE_256"
        SIGNATURE_PREFIX = "sha256="
        SIGNATURE_DIGEST = "SHA256"

        # Rack stashes the exact bytes it read while parsing an urlencoded body
        # here, which is what we need: reading `params[:payload]` has already
        # consumed `rack.input` by the time this action runs.
        RACK_FORM_VARS = "rack.request.form_vars"

        def verify_csrf_token?(request, response)
          false
        end

        def handle(request, response)
          # The book is looked up first so a webhook pointed at a permalink that
          # does not exist still fails loudly in GitHub's UI with a 404, and so
          # we know which secret (if any) the delivery has to be signed with.
          case find_book.(permalink: request.params[:permalink])
          in Failure(:book_not_found)
            book_not_found(response)
          in Success(book)
            return invalid_signature(response) unless verified?(request, book)

            if request.get_header(GITHUB_EVENT_HEADER) == "ping"
              handle_ping(response)
            else
              handle_push(request, response)
            end
          end
        end

        private

        # GitHub sends a ping when a webhook is first created. There's nothing
        # to process, but it is signed like any other delivery, so it goes
        # through the same verification as a push.
        def handle_ping(response)
          response.status = 200
          response.format = :json
          response.body = {message: "pong"}.to_json
        end

        def handle_push(request, response)
          payload = JSON.parse(request.params[:payload])

          result = receive_book.(
            permalink: request.params[:permalink],
            branch_name: payload["ref"],
            event: request.env["HTTP_X_GITHUB_EVENT"],
            delivery_id: request.env["HTTP_X_GITHUB_DELIVERY"]
          )

          case result
          in Failure(:book_not_found)
            book_not_found(response)
          else
            response.status = 200
          end
        end

        # Books without a secret keep accepting unsigned deliveries, so books
        # set up before signature verification existed do not break. Once an
        # author sets a secret, every delivery for that book must be signed
        # with it.
        def verified?(request, book)
          secret = book.webhook_secret
          return true if secret.nil? || secret.empty?

          signature = request.get_header(SIGNATURE_HEADER).to_s
          return false unless signature.start_with?(SIGNATURE_PREFIX)

          expected = SIGNATURE_PREFIX + OpenSSL::HMAC.hexdigest(
            SIGNATURE_DIGEST, secret, raw_body(request)
          )

          secure_compare(signature, expected)
        end

        # Digests are the same length for a well-formed signature, but an
        # attacker-supplied header need not be, and `fixed_length_secure_compare`
        # raises when the lengths differ.
        def secure_compare(given, expected)
          return false unless given.bytesize == expected.bytesize

          OpenSSL.fixed_length_secure_compare(given, expected)
        end

        # The bytes GitHub signed. This action reads the push payload out of a
        # form-urlencoded body, so by the time `handle` runs Rack has already
        # read `rack.input` — and Rack 3 does not promise that input is
        # rewindable. Rack does keep the raw form body in `rack.request.form_vars`
        # while parsing it, which is exactly what was signed, so that is the
        # primary source; rewinding is only a fallback for bodies Rack did not
        # parse as a form (a JSON delivery, say).
        def raw_body(request)
          form_vars = request.env[RACK_FORM_VARS]
          return form_vars if form_vars

          input = request.env[::Rack::RACK_INPUT]
          return "" unless input.respond_to?(:rewind) && input.respond_to?(:read)

          input.rewind
          body = input.read.to_s
          input.rewind
          body
        rescue IOError, Errno::ESPIPE, NotImplementedError
          ""
        end

        def invalid_signature(response)
          response.status = 401
          response.format = :json
          response.body = {error: "Invalid webhook signature"}.to_json
        end

        def book_not_found(response)
          response.status = 404
          response.format = :json
          response.body = {error: "Book not found"}.to_json
        end
      end
    end
  end
end
