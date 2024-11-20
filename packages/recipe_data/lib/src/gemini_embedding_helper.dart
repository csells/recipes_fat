import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiEmbeddingHelper {
  GeminiEmbeddingHelper(this.model);
  final GenerativeModel model;

  /// Retrieves the embedding for a given document.
  ///
  /// This method takes a document as input and returns its embedding as a list
  /// of doubles. The embedding is generated using the specified model and is
  /// suitable for retrieval tasks.
  ///
  /// [document] is the input document for which the embedding is to be generated.
  ///
  /// Returns a Future that completes with the embedding of the document as a List<double>.
  Future<List<double>> getDocumentEmbedding(String document) =>
      _getEmbedding(document, TaskType.retrievalDocument);

  /// Retrieves the embedding for a given query.
  ///
  /// This method takes a query as input and returns its embedding as a list
  /// of doubles. The embedding is generated using the specified model and is
  /// suitable for retrieval tasks.
  ///
  /// [query] is the input query for which the embedding is to be generated.
  ///
  /// Returns a Future that completes with the embedding of the query as a List<double>.
  Future<List<double>> getQueryEmbedding(String query) =>
      _getEmbedding(query, TaskType.retrievalQuery);
  Future<List<double>> _getEmbedding(String s, TaskType embeddingTask) async {
    assert(embeddingTask == TaskType.retrievalDocument ||
        embeddingTask == TaskType.retrievalQuery);

    final content = Content.text(s);
    final result = await model.embedContent(
      content,
      taskType: embeddingTask,
    );

    return result.embedding.values;
  }

  /// Computes the dot product of two embedding vectors represented as lists of
  /// doubles.
  ///
  /// This method calculates the sum of the products of corresponding elements
  /// in two vectors. It's commonly used in various machine learning and natural
  /// language processing tasks, such as computing similarity between
  /// embeddings.
  ///
  /// [e1] is the first vector, represented as a List<double>. [e2] is the
  /// second vector, represented as a List<double>.
  ///
  /// Both input vectors must have the same length. If they don't, this method
  /// will throw a RangeError when accessing elements.
  ///
  /// Returns a double representing the dot product of the two input vectors.
  static double computeDotProduct(List<double> a, List<double> b) {
    double sum = 0.0;
    for (var i = 0; i < a.length; ++i) {
      sum += a[i] * b[i];
    }

    return sum;
  }
}
