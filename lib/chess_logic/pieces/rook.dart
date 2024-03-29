import 'package:chess_opening_diary/chess_logic/pieces/piece.dart';

import '../piece_move_algorithms/piece_move_algorithm.dart';
import '../piece_move_algorithms/piece_move_step.dart';

class Rook extends Piece{
  Rook(bool lightPiece):super(lightPiece, (lightPiece ? 'lightRook' : 'darkRook'), _getPieceMoveAlgo());

  static PieceMoveAlgorithm _getPieceMoveAlgo(){
    PieceMoveAlgorithm result = PieceMoveAlgorithm(isRepeatable: true, baseMoves: PieceMoveStep.rookType);
    return result;
  }
}