import 'package:chess_opening_diary/chess_logic/pieces/piece.dart';

import '../piece_move_algorithms/piece_move_algorithm.dart';
import '../piece_move_algorithms/piece_move_step.dart';

class Knight extends Piece{
  Knight(bool lightPiece):super(lightPiece, getImageKeyForColor(lightPiece), _getPieceMoveAlgo());

  static PieceMoveAlgorithm _getPieceMoveAlgo(){
    PieceMoveStep a = PieceMoveStep(x: 1, y: 2, stepCapturableType: StepCapturableType.both);
    PieceMoveStep b = PieceMoveStep(x: 1, y: -2, stepCapturableType: StepCapturableType.both);
    PieceMoveStep c = PieceMoveStep(x: -1, y: 2, stepCapturableType: StepCapturableType.both);
    PieceMoveStep d = PieceMoveStep(x: -1, y: -2, stepCapturableType: StepCapturableType.both);
    PieceMoveStep e = PieceMoveStep(x: 2, y: 1, stepCapturableType: StepCapturableType.both);
    PieceMoveStep f = PieceMoveStep(x: 2, y: -1, stepCapturableType: StepCapturableType.both);
    PieceMoveStep g = PieceMoveStep(x: -2, y: 1, stepCapturableType: StepCapturableType.both);
    PieceMoveStep h = PieceMoveStep(x: -2, y: -1, stepCapturableType: StepCapturableType.both);
    PieceMoveAlgorithm result = PieceMoveAlgorithm(isRepeatable: false, baseMoves: [a, b, c, d, e, f, g, h]);
    return result;
  }

  static String getImageKeyForColor(bool lightPiece){
    return (lightPiece ? 'lightKnight' : 'batman');
  }
}