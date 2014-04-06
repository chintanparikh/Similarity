require 'matrix'

class Matrix
  def []=(i, j, x)
    @rows[i][j] = x
  end
end

class TermDocumentMatrix
  attr_reader :matrix, :labels, :number_of_terms, :number_of_documents, :non_zeros

  def initialize(corpus)
    # @matrix = GSL::Matrix.alloc(corpus.terms.size, corpus.document_count)
    @matrix = Matrix.build(corpus.terms.size, corpus.document_count) {0}
    @non_zeros = 0
    @number_of_terms = corpus.terms.size
    @number_of_documents = corpus.documents.size

    corpus.terms.each_with_index do |term, term_index|
      term = term.first
      idf = corpus.inverse_document_frequency(term)

      corpus.documents.each_with_index do |document, document_index|
        weight = document.term_frequency(term) * idf
        @matrix[term_index, document_index] = weight
        @non_zeros += 1 unless weight.zero?
      end
    end

    # @matrix.each_col { |col| col.div!(col.norm) }
    @matrix = Matrix.columns(@matrix.column_vectors.map{|c| c.normalize})
    @labels = corpus.terms.to_a.map {|e| e[0]}
  end

  def similarity_matrix
    self.matrix.transpose * self.matrix
  end

  def col(idx)
    @matrix.column_vectors[idx]
  end

  def to_a
    @matrix.to_a
  end
end
