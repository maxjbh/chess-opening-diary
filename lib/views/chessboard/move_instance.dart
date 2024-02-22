import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_step.dart';
import 'package:chess_opening_diary/views/chessboard/tile.dart';

import '../../chess_logic/pieces/piece.dart';

///Utility class to hold data about a in-chessboardController move.
///That is from, to, movingPiece and the pieceMoveStep
class MoveInstance{

  MoveInstance({required this.from, required this.to, required this.movingPiece, required this.pieceMoveStep});

  Tile from;
  Tile to;
  Piece movingPiece;
  PieceMoveStep pieceMoveStep;
}