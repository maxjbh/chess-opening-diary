part of 'chessboard_controller_cubit.dart';

@immutable
abstract class ChessboardControllerState {}

class ChessboardControllerInitial extends ChessboardControllerState {}

class ChessboardNoSelectionState extends ChessboardControllerState {}

class CheckmateState extends ChessboardControllerState {}

///A state so that the interface knows to handle next click differently
class PieceSelectedState extends ChessboardControllerState{
  PieceSelectedState():super();
}
