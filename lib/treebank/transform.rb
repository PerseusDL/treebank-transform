require "treebank/transform/version"
require "nokogiri"

module Treebank
  require "treebank/sentence"
  require "treebank/elliptic_word"

  STYLESHEETS = File.expand_path('../../../stylesheets', __FILE__)
  BETA_2_UNICODE = 'treebank-beta-uni.xsl'

  class Transform
    def initialize(doc)
      @doc  = Nokogiri::XML(doc);
    end

    def transform
      transform_sentence_level
      transform_document_level

      @doc.to_xml(indent: 2)
    end

    def extract_cts_name(extension = '')
      # TODO - needs to be implemented still
      "test#{extension}"
    end

    private

    def transform_document_level
      beta2unicode
    end

    def beta2unicode
      Dir.chdir(STYLESHEETS) do
        @xslt = Nokogiri::XSLT(File.read(BETA_2_UNICODE))
        @doc = @xslt.transform(@doc)
      end
    end

    def transform_sentence_level
      @doc.xpath('//treebank/sentence').each do |sentence_node|
        sentence = Sentence.new(sentence_node)
        sentence_node.xpath('word').each do |word_node|
          transform_elliptic_nodes(sentence, word_node)
          transform_participles(word_node)
        end
      end
    end

    def transform_elliptic_nodes(sentence, word_node)
      if has_elliptic_head(word_node['relation'])
        word = EllipticWord.new(word_node, sentence)
        word.parse_elliptic_head
      end
    end

    def has_elliptic_head(label)
      label.match(/ExD\d+/)
    end

    def transform_participles(node)
      postag = node['postag']
      if postag.start_with?('t')
        node['postag'] = postag.sub('t', 'v')
      end
    end
  end
end
