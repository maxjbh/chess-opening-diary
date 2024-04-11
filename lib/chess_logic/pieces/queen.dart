import 'package:chess_opening_diary/chess_logic/pieces/piece.dart';

import '../piece_move_algorithms/piece_move_algorithm.dart';
import '../piece_move_algorithms/piece_move_step.dart';

class Queen extends Piece{
  Queen(bool lightPiece):super(lightPiece, getImageKeyForColor(lightPiece), _getPieceMoveAlgo());

  static PieceMoveAlgorithm _getPieceMoveAlgo(){
    PieceMoveAlgorithm result = PieceMoveAlgorithm(isRepeatable: true, baseMoves: PieceMoveStep.bishopType + PieceMoveStep.rookType);
    return result;
  }

  static String getImageKeyForColor(bool lightPiece){
    return (lightPiece ? 'lightQueen' : 'darkQueen');
  }
}