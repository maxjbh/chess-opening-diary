part of 'chessboard_controller_cubit.dart';

@immutable
abstract class ChessboardControllerState {}

class ChessboardControllerInitial extends ChessboardControllerState {}

class ChessboardNoSelectionState extends ChessboardControllerState {}

class CheckmateState extends ChessboardControllerState {}

class PromotingState extends ChessboardControllerState {
  int atX;
  int atY;
  PromotingState(this.atX, this.atY):super();
}

///A state so that the interface knows to handle next click differently
class PieceSelectedState extends ChessboardControllerState{
  PieceSelectedState():super();
}
