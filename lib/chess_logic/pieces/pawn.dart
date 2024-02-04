import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_algorithm.dart';
import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_step.dart';
import 'package:chess_opening_diary/chess_logic/pieces/piece.dart';

class Pawn extends Piece{
  Pawn(bool lightPiece):super(lightPiece, (lightPiece ? 'lightPawn' : 'darkPawn'), _getPieceMoveAlgo());

  bool isPassantable = false;

  static PieceMoveAlgorithm _getPieceMoveAlgo(){
    PieceMoveStep a = PieceMoveStep(x: 0, y: 1, stepCapturableType: StepCapturableType.nonCapturable);
    PieceMoveStep b = PieceMoveStep(x: 1, y: 1, stepCapturableType: StepCapturableType.onlyCapturable);
    PieceMoveStep c = PieceMoveStep(x: -1, y: 1, stepCapturableType: StepCapturableType.onlyCapturable);
    PieceMoveStep d = PieceMoveStep(x: 0, y: 2, stepCapturableType: StepCapturableType.nonCapturable);
    PieceMoveAlgorithm result = PieceMoveAlgorithm(isRepeatable: false, baseMoves: [a, b, c, d]);
    return result;
  }

  static PieceMoveStep getRealCoordinateChangeForMove(PieceMoveStep input, bool asWhite, bool fromWhitesPerspective){
    int realXChange = input.x;
    int realYChange = -1*input.y;
    if(fromWhitesPerspective != asWhite){
      realXChange = -1*input.x;
      realYChange = input.y;
    }
    return PieceMoveStep(x: realXChange, y: realYChange, stepCapturableType: input.stepCapturableType);
  }
}