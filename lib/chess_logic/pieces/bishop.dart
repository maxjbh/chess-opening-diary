import 'package:chess_opening_diary/chess_logic/pieces/piece.dart';

import '../piece_move_algorithms/piece_move_algorithm.dart';
import '../piece_move_algorithms/piece_move_step.dart';

class Bishop extends Piece{
  Bishop(bool lightPiece):super(lightPiece, (lightPiece ? 'lightBishop' : 'darkBishop'), _getPieceMoveAlgo());

  static PieceMoveAlgorithm _getPieceMoveAlgo(){
    PieceMoveAlgorithm result = PieceMoveAlgorithm(isRepeatable: true, baseMoves: PieceMoveStep.bishopType);
    return result;
  }
}