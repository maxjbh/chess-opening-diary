class PieceMoveStep{
  PieceMoveStep({required this.x, required this.y, required this.stepCapturableType});

  final StepCapturableType stepCapturableType;
  final int x;
  final int y;

  ///Sais if the move heads in the right general direction.
  ///0 is Up-left, up and up-right.
  ///7 is left, up-left, up.
  bool validatesCompassDirection(int compassDirection){
    if(x==0){
      if(y>=1){
        return compassDirection==7 || compassDirection==0 || compassDirection==1;
      }else{
        return compassDirection==5 || compassDirection==4 || compassDirection==3;
      }
    }
    if(y==0){
      if(x>=1){
        return compassDirection==1 || compassDirection==2 || compassDirection==3;
      }else{
        return compassDirection==7 || compassDirection==6 || compassDirection==5;
      }
    }
    if(x>=1){
      if(y>=1){
        return compassDirection==0 || compassDirection==1 || compassDirection==2;
      }else{
        return compassDirection==2 || compassDirection==3 || compassDirection==4;
      }
    }
    if(y>=1){
      return compassDirection==0 || compassDirection==7 || compassDirection==6;
    }
    return compassDirection==6 || compassDirection==5 || compassDirection==4;
  }

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