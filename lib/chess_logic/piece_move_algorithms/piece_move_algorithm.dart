import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_step.dart';

class PieceMoveAlgorithm{
  PieceMoveAlgorithm({required this.isRepeatable, required this.baseMoves});

  final bool isRepeatable;
  final List<PieceMoveStep> baseMoves;
}