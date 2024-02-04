import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_algorithm.dart';

abstract class Piece{
  Piece(this.lightPiece, this.imageKey, this.pieceMoveAlgorithm);

  final bool lightPiece;
  final String imageKey;
  final PieceMoveAlgorithm pieceMoveAlgorithm;
  //TODO set this to true after it moves, and handle enPassantable
  bool hasMoved = false;
}
