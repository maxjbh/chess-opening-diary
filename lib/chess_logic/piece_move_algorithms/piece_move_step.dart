class PieceMoveStep{
  PieceMoveStep({required this.x, required this.y, required this.stepCapturableType});

  final StepCapturableType stepCapturableType;
  final int x;
  final int y;

  static final List<PieceMoveStep> rookType = [
    PieceMoveStep(x: 0, y: 1, stepCapturableType: StepCapturableType.both),
    PieceMoveStep(x: 1, y: 0, stepCapturableType: StepCapturableType.both),
    PieceMoveStep(x: -1, y: 0, stepCapturableType: StepCapturableType.both),
    PieceMoveStep(x: 0, y: -1, stepCapturableType: StepCapturableType.both)
  ];
  static final List<PieceMoveStep> bishopType = [
    PieceMoveStep(x: 1, y: 1, stepCapturableType: StepCapturableType.both),
    PieceMoveStep(x: 1, y: -1, stepCapturableType: StepCapturableType.both),
    PieceMoveStep(x: -1, y: -1, stepCapturableType: StepCapturableType.both),
    PieceMoveStep(x: -1, y: 1, stepCapturableType: StepCapturableType.both)
  ];
}

enum StepCapturableType{
  onlyCapturable,
  nonCapturable,
  both
}