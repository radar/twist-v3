# frozen_string_literal: true

RSpec.describe Users::Actions::Sessions::New do
  let(:params) { Hash[] }

  it "works" do
    response = subject.call(params)
    expect(response).to be_successful
  end
end
