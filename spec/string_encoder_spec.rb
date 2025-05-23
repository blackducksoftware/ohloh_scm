# frozen_string_literal: true

require 'spec_helper'

describe 'string_encoder' do
  before do
    @object = Object.new
    @object.extend(OhlohScm::System)
    def @object.string_encoder
      string_encoder_path
    end
  end

  it 'preserve length of translated content' do
    file_path = FIXTURES_DIR + '/sample-content'
    original_content_length = File.size(file_path)
    original_content_lines = File.readlines(file_path).size

    output = `cat #{file_path} | #{@object.string_encoder}`

    assert_equal original_content_length, output.length
    assert_equal original_content_lines, output.split("\n").length
  end

  it 'must convert invalid characters' do
    invalid_utf8_word_path = FIXTURES_DIR + '/invalid-utf-word'

    string = `cat #{invalid_utf8_word_path} | #{@object.string_encoder}`

    assert_equal true, string.valid_encoding?
  end
end
