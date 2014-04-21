require 'matrix'

class Corpus
  attr_reader :terms, :documents

  def initialize
    @terms = Hash.new(0)
    @documents = []
    @term_document_matrix = nil
    @similarity_matrix = nil
  end

  def document_count
    @documents.size
  end

  def <<(document)
    document.terms.uniq.each { |term| @terms[term] += 1 }
    @documents << document
    @term_document_matrix = nil
    @similarity_matrix = nil
  end

  def remove(document)
    document.terms.uniq.each { |term| @terms[term] -= 1 }
    @documents.delete(document)
  end

  def remove_infrequent_terms!(percentage)
    number_of_docs = document_count.to_f
    @terms = terms.delete_if {|term, count| (count.to_f / number_of_docs) < percentage}
    @term_document_matrix = nil
    @similarity_matrix = nil
  end

  def remove_frequent_terms!(percentage)
    number_of_docs = document_count.to_f
    @terms = terms.delete_if {|term, count| (count.to_f / number_of_docs) > percentage}
    @term_document_matrix = nil
    @similarity_matrix = nil
  end

  def inverse_document_frequency(term)
    puts "#{document_count} / (1 + #{document_count_for_term(term)})" if $DEBUG
    Math.log(document_count.to_f / (1 + document_count_for_term(term)))
  end

  def document_count_for_term(term)
    @terms[term]
  end

  def similarity_matrix
    @similarity_matrix ||= term_document_matrix.similarity_matrix
  end

  def term_document_matrix
    @term_document_matrix ||= TermDocumentMatrix.new(self)
  end

  def similar_documents(document)
    index = documents.index(document)
    return nil if index.nil?

    results = documents.each_with_index.map do |doc, doc_index|
      next if document == doc
      similarity = similarity_matrix[index, doc_index]
      # puts "#{similarity} - #{doc.id}"
      [doc, similarity]
    end
    results = results.reject{|e| e == nil}
    results.sort { |a,b| b.last <=> a.last } 
  end

  def weights(document)
    idx = @documents.index(document)
    terms = @terms.to_a.map {|term| term.first}
    weights = term_document_matrix.col(idx).to_a

    # create array of array pairs of terms and weights
    term_weight_pairs = terms.zip(weights)

    # remove zero weights
    term_weight_pairs.reject! {|pair| pair[1].zero?}

    # sort in descending order
    term_weight_pairs.sort {|x,y| y[1] <=> x[1]}
  end
end
