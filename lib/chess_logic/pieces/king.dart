import 'package:chess_opening_diary/chess_logic/pieces/piece.dart';

import '../piece_move_algorithms/piece_move_algorithm.dart';
import '../piece_move_algorithms/piece_move_step.dart';

class King extends Piece{
  King(bool lightPiece):super(lightPiece, (lightPiece ? 'lightKing' : 'darkKing'), _getPieceMoveAlgo());

  static PieceMoveAlgorithm _getPieceMoveAlgo(){
    List<PieceMoveStep> possibleMoves = PieceMoveStep.bishopType + PieceMoveStep.rookType;
    //Castle from whites perspective as white
    possibleMoves.add(PieceMoveStep(x: 2, y: 0, stepCapturableType: StepCapturableType.nonCapturable));
    possibleMoves.add(PieceMoveStep(x: -2, y: 0, stepCapturableType: StepCapturableType.nonCapturable));
    PieceMoveAlgorithm result = PieceMoveAlgorithm(isRepeatable: false, baseMoves: possibleMoves);
    return result;
  }

}