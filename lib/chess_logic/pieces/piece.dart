import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_algorithm.dart';

abstract class Piece{
  Piece(this.lightPiece, this.imageKey, this.pieceMoveAlgorithm);

  final bool lightPiece;
  final String imageKey;

  /// Sais how to calculate where the piece can move
  final PieceMoveAlgorithm pieceMoveAlgorithm;
  bool hasMoved = false;
}
