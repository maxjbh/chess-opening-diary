import 'package:bloc/bloc.dart';
import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_algorithm.dart';
import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_step.dart';
import 'package:chess_opening_diary/views/chessboard/tile.dart';
import 'package:flutter/material.dart';

import '../../chess_logic/piece_move_algorithms/piece_move_step.dart';
import '../../chess_logic/pieces/bishop.dart';
import '../../chess_logic/pieces/king.dart';
import '../../chess_logic/pieces/knight.dart';
import '../../chess_logic/pieces/pawn.dart';
import '../../chess_logic/pieces/piece.dart';
import '../../chess_logic/pieces/queen.dart';
import '../../chess_logic/pieces/rook.dart';

part 'chessboard_controller_state.dart';

class ChessboardControllerCubit extends Cubit<ChessboardControllerState> {

  ChessboardControllerCubit({required this.size, List<List<Tile>>? tilesData, required this.fromWhitesPerspective})
      : tilesData = tilesData ?? generateStandardStartingPosition(fromWhitesPerspective), super(ChessboardControllerInitial());

  ValueNotifier<int> boardPainterUpdateNotifier = ValueNotifier<int>(0);
  final double size;
  final bool fromWhitesPerspective;
  bool isWhitesTurn = true;
  ///This is a list of ROWS, so y is a coordinate of the first list
  final List<List<Tile>> tilesData;

  /*///So that we can quickly revert is the move isn't performed
  List<List<Tile>>? tilesDataBeforeSelect;*/

  List<Tile> tilesWithMoveToIndicator = [];

  List<Tile> tilesWithCaptureCircle = [];

  ///A single memory slot as there can only ever be one
  Tile? passantablePieceContainer;

  ///The currently selected tile
  Tile? selectedTile;

  bool shouldRepaint = false;

  //TODO handle pieces not being able to reveal a check on own king

  void handleClick(TapDownDetails pointerEvent){
    int realX = ((8*pointerEvent.localPosition.dx)/size).floor();
    int realY = ((8*pointerEvent.localPosition.dy)/size).floor();

    if(selectedTile != null){
      _moveToOrUnselect(realX, realY, selectedTile!);
    }else{
      _selectTileAt(realX, realY, isWhitesTurn);
    }

  }

  ///Moves the selected piece to the square if we can go there, otherwise unselects the piece.
  ///selectedTile is the tile we are moving FROM.
  ///Handles castling
  void _moveToOrUnselect(int x, int y, Tile selectedTile){
    Tile nextSquare = tilesData.elementAt(y).elementAt(x);
    if(nextSquare.isPossibleMove || nextSquare.doDrawCaptureCircle){
      Piece? movingPiece = selectedTile.piece;
      //Handle en-passant and castling
      handleEnPassantForMove(nextSquare, movingPiece, y);
      handleCastleMove(movingPiece, x, y);
      movingPiece?.hasMoved = true;
      nextSquare.setPiece(movingPiece);
      selectedTile.setPiece(null);
      isWhitesTurn = !isWhitesTurn;
    }
    selectedTile.isSelected = false;
    this.selectedTile = null;
    for(Tile tile in tilesWithCaptureCircle){
      tile.doDrawCaptureCircle = false;
    }
    for(Tile tile in tilesWithMoveToIndicator){
      tile.isPossibleMove = false;
    }
    tilesWithCaptureCircle = [];
    tilesWithMoveToIndicator = [];
    shouldRepaint = true;
    emit(ChessboardNoSelectionState());
  }

  ///Extracted as the order of operations is important.
  ///1. Identify if our move is a take en-passant, if so remove the piece then unset passantablePieceContainer to not get a null Pawn in the next step
  ///2. Always unset passantablePieceContainer on any move because we know a piece is only passantable for one turn
  ///3. After handling potential previous en-passant see if the next move is creating a new passantable piece
  void handleEnPassantForMove(Tile nextSquare, Piece? movingPiece, int nextY){
    //Check if we are taking passantable piece so we can handle it before unsetting
    Piece? attackedPiece = nextSquare.piece;
    if(attackedPiece == null && nextSquare.doDrawCaptureCircle){
      passantablePieceContainer?.setPiece(null);
      passantablePieceContainer = null;
    }
    //Unset passantable piece before potentially setting new one
    if(passantablePieceContainer != null){
      (passantablePieceContainer?.piece as Pawn).isPassantable = false;
      passantablePieceContainer = null;
    }
    //Set isPassantable
    if(movingPiece != null && (movingPiece is Pawn) && !movingPiece.hasMoved && nextSquare.isPossibleMove && (nextY - selectedTile!.y).abs() == 2){
      movingPiece.isPassantable = true;
      passantablePieceContainer = nextSquare;
    }
  }

  ///1. Checks if the move is a castle move.
  ///2. Handle moving the rook during the move
  void handleCastleMove(Piece? movingPiece, int nextX, int nextY){
    if(movingPiece == null || movingPiece is! King || movingPiece.hasMoved || (nextX!=2 && nextX!=6)){
      return;
    }
    //(If nextX==6) :
    Tile rookToMoveContainer = tilesData.elementAt(nextY).elementAt(7);
    Tile rookHeadingTo = tilesData.elementAt(nextY).elementAt(5);
    if(nextX==2){
      rookToMoveContainer = tilesData.elementAt(nextY).elementAt(0);
      rookHeadingTo = tilesData.elementAt(nextY).elementAt(3);
    }
    Piece? rookToMove = rookToMoveContainer.piece;
    rookHeadingTo.setPiece(rookToMove);
    rookToMoveContainer.setPiece(null);
  }

  //TODO infinite loop when hitting a king (or all pieces?) that cant move anywhere?

  ///Constructs new tilesData containing possible moves for this piece
  ///Precondition : a tile wasn't already selected
  void _selectTileAt(int x, int y, bool asWhite){
    Tile selectedTile = tilesData.elementAt(y).elementAt(x);
    Piece? piece = selectedTile.piece;
    if(piece==null || piece.lightPiece!=asWhite){
      return;
    }
    selectedTile.isSelected = true;
    this.selectedTile = selectedTile;
    PieceMoveAlgorithm pieceMoveAlgorithm = piece.pieceMoveAlgorithm;
    for(PieceMoveStep pieceMoveStep in pieceMoveAlgorithm.baseMoves){
      if(pieceMoveAlgorithm.isRepeatable){
        _repeatDirection(x, y, pieceMoveStep, asWhite, piece, _checkNextTileForActivePieceMoveIndicator, null, null, 0);
      }else{
        PieceMoveStep realMove = pieceMoveStep;
        if(piece is Pawn){
          if(pieceMoveStep.y == 2 && piece.hasMoved){
            continue;
          }
          realMove = Pawn.getRealCoordinateChangeForMove(pieceMoveStep, asWhite, fromWhitesPerspective);
        }
        if(piece is King){
          if(pieceMoveStep.x.abs() == 2){
            if(!_checkIfWeCanCastleFrom(x, y, asWhite, piece, pieceMoveStep)){
              continue;
            }
          }
        }
        int nextX = x + realMove.x;
        int nextY = y + realMove.y;
        _checkNextTileForActivePieceMoveIndicator(nextX, nextY, asWhite, piece, realMove);
      }
    }
    setShouldRepaint(true);
    emit(PieceSelectedState());
  }

  setShouldRepaint(bool shouldRepaint){
    this.shouldRepaint = shouldRepaint;
  }

  ///Repeats a step into a given direction until it hits a piece or the side of the board
  ///OnNextTile returns a bool to say if we should continue, as well as running any specific code
  ///onFinish handles returning something
  ///Extra args holds any specific stuff
  ///dynamic type so we can return something if we need to
  dynamic _repeatDirection(
      int x,
      int y,
      PieceMoveStep step,
      bool asWhite,
      Piece activePiece,
      bool Function(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep step) onNextTileDoContinue,
      dynamic Function(int xFinish, int yFinish, bool asWhite, Piece activePiece)? onFinish,
      bool Function(int nextX, int nextY, int iteratorCount)? extraCanContinueCheck,
      int iteratorCount
      ){
    int nextX = x + step.x;
    int nextY = y + step.y;
    bool canContinue = onNextTileDoContinue(nextX, nextY, asWhite, activePiece, step);
    if(canContinue && extraCanContinueCheck != null){
      canContinue = extraCanContinueCheck(nextX, nextY, iteratorCount);
    }
    if(canContinue){
      return _repeatDirection(nextX, nextY, step, asWhite, activePiece, onNextTileDoContinue, onFinish, extraCanContinueCheck, iteratorCount++);
    }else{
      if(onFinish != null){
        //Only call onFinish with nextX and nextY if there are still on the board,
        // otherwise call with the last tile that wasn't empty
        // (so that we don't also have to do checks in the passed onFinish function)
        if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
          return onFinish(x, y, asWhite, activePiece);
        }else{
          dynamic returnValue = onFinish(nextX, nextY, asWhite, activePiece);
          return returnValue;
        }
      }
      return null;
    }
  }

  ///Checks if next tile is edge or a piece, no extra code
  bool _checkNextTile(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep step){
    if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
      return false;
    }
    Tile nextTile = tilesData.elementAt(nextY).elementAt(nextX);
    Piece? nextTilesPiece = nextTile.piece;
    return nextTilesPiece==null;
  }

  ///Checks if next tile is edge or a piece, but returns true if the piece is the current players king (white king if its white's turn)
  bool _checkNextTileIgnoreCurrentPlayersKing(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep step){
    if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
      return false;
    }
    Tile nextTile = tilesData.elementAt(nextY).elementAt(nextX);
    Piece? nextTilesPiece = nextTile.piece;
    if(nextTilesPiece != null && nextTilesPiece is King && nextTilesPiece.lightPiece == isWhitesTurn){
      return true;
    }
    return nextTilesPiece==null;
  }

  
  ///checks if a move has a piece, sets the tile isMovable and doDrawCaptureCircle booleans, if not null.
  ///Returns a bool that is true if no same-sided piece was found and we still haven't fallen of the board.
  ///Handles king not being able to go into check
  ///Handles en passant
  bool _checkNextTileForActivePieceMoveIndicator(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep move){
    if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
      return false;
    }
    Tile nextTile = tilesData.elementAt(nextY).elementAt(nextX);
    Piece? nextTilesPiece = nextTile.piece;
    if(nextTilesPiece==null){
      if(move.stepCapturableType != StepCapturableType.onlyCapturable){
        //Check that king isn't moving into a check
        if(activePiece is King){
          bool opposingCanSeeNextTile = _checkIfOpposingSideCovers(nextX, nextY, asWhite, _checkNextTileIgnoreCurrentPlayersKing);
          if(opposingCanSeeNextTile){
            //Note the value of this return isn't important, its just to quit the function
            return false;
          }
        }
        tilesWithMoveToIndicator.add(nextTile);
        nextTile.isPossibleMove = true;
        return true;
      }
      if(activePiece is Pawn && move.stepCapturableType == StepCapturableType.onlyCapturable){
        //Handle en passant
        Tile candidate;
        Piece? candidatePiece;
        if(asWhite != fromWhitesPerspective){
          //look at nextY - 1
          candidate = tilesData.elementAt(nextY - 1).elementAt(nextX);
          candidatePiece = candidate.piece;
        }else{
          //look at nexty + 1
          candidate = tilesData.elementAt(nextY + 1).elementAt(nextX);
          candidatePiece = candidate.piece;
        }
        if(candidatePiece != null && candidatePiece is Pawn && candidatePiece.lightPiece != asWhite && candidatePiece.isPassantable){
          tilesWithCaptureCircle.add(nextTile);
          nextTile.doDrawCaptureCircle = true;
        }
      }
      return false;
    }
    if(nextTilesPiece.lightPiece!=asWhite && move.stepCapturableType != StepCapturableType.nonCapturable){
      //Check that king isn't moving into a check
      if(activePiece is King){
        bool opposingCanSeeNextTile = _checkIfOpposingSideCovers(nextX, nextY, asWhite, _checkNextTileIgnoreCurrentPlayersKing);
        if(opposingCanSeeNextTile){
          //Note the value of this return isn't important, its just to quit the function
          return false;
        }
      }
      tilesWithCaptureCircle.add(nextTile);
      nextTile.doDrawCaptureCircle = true;
    }
    return false;
  }

  ///Precondition, the piece is a king
  bool _checkIfWeCanCastleFrom(int x, int y, bool asWhite, King activePiece, PieceMoveStep move){
    //TODO add can't castle out of check
    if(activePiece.hasMoved){
      return false;
    }
    PieceMoveStep convertedToOneStep = PieceMoveStep(x: (move.x/2) as int, y: move.y, stepCapturableType: move.stepCapturableType);
    return _repeatDirection(
        x,
        y,
        convertedToOneStep,
        asWhite,
        activePiece,
        _checkNextTile,
        (xFinish, yFinish, asWhite, activePiece){
          Piece? pieceReached = tilesData.elementAt(yFinish).elementAt(xFinish).piece;
          return pieceReached!=null && pieceReached is Rook && pieceReached.lightPiece==asWhite && !pieceReached.hasMoved;
        },
        (int nextX, int nextY, int iteratorCount){
          //only check on 0 as last tile gets verified for check anyway
          if(iteratorCount < 1){
            return !_checkIfOpposingSideCovers(nextX, nextY, asWhite, _checkNextTile);
          }
          return true;
        },
        0
    );
  }

  ///Returns true if the opposing side does cover this square.
  ///Including the enemy king even if it would be putting itself in check.
  ///Prop checkNextTileFunction is here to say if we need ignore the player who's verifying king
  bool _checkIfOpposingSideCovers(
      int x,
      int y,
      bool asWhite,
      bool Function(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep step)  checkNextTile
    ){
    int rowIndex = 0;
    for(List<Tile> row in tilesData){
      int colIndex = 0;
      for(Tile tile in row){
        Piece? piece = tile.piece;
        //If there is a piece and its of opposing color we can check if it covers tile at x, y
        if(piece != null && piece.lightPiece != asWhite){
          PieceMoveAlgorithm algo = piece.pieceMoveAlgorithm;
          if(algo.isRepeatable){
            //See if there is a possible direction then see if that direction takes us to x, y without hitting a piece
            PieceMoveStep? candidateMove;
            for(PieceMoveStep move in algo.baseMoves){
              if(move.x != 0 && move.y != 0){
                //Check that the x and y differences are the same then check that we are going in correct direction
                if((x - colIndex).abs() == (y - rowIndex).abs() && _stepChangeTakesUsCloser(colIndex, x, move.x) && _stepChangeTakesUsCloser(rowIndex, y, move.y)){
                  candidateMove = move;
                  break;
                }
              }else{
                if(move.x == 0){
                  //Vertical move along y axis, so x needs to be same, and we need to be heading in correct direction along y axis
                  if(x == colIndex && _stepChangeTakesUsCloser(rowIndex, y, move.y)){
                    candidateMove = move;
                    break;
                  }
                }else{
                  //move.y == 0, horizontal move, y needs to be the same, and we need to be heading in correct direction along x axis
                  if(y == rowIndex && _stepChangeTakesUsCloser(colIndex, x, move.x)){
                    candidateMove = move;
                    break;
                  }
                }
              }
            }
            if(candidateMove != null){
              bool doesSeeTile = _repeatDirection(
                  colIndex,
                  rowIndex,
                  candidateMove,
                  !asWhite,
                  piece,
                  checkNextTile,
                  (int xFinish, int yFinish, bool asWhite, Piece activePiece){return xFinish == x && yFinish == y;},
                  (int lastX, int lastY, int iteratorCount){return lastX != x && lastY != y;},
                  0
              ) as bool;
              if(doesSeeTile){
                return doesSeeTile;
              }
            }
          }else{
            if(piece is Pawn){
              for(PieceMoveStep move in algo.baseMoves){
                if(move.stepCapturableType == StepCapturableType.onlyCapturable){
                  PieceMoveStep realMove = Pawn.getRealCoordinateChangeForMove(move, !asWhite, fromWhitesPerspective);
                  if(realMove.y + rowIndex == y && realMove.x + colIndex == x){
                    return true;
                  }
                }
              }
            }else{
              for(PieceMoveStep move in algo.baseMoves){
                int nextX = colIndex + move.x;
                int nextY = rowIndex + move.y;
                if(nextX == x && nextY == y){
                  return true;
                }
              }
            }
          }
        }
        colIndex++;
      }
      rowIndex++;
    }
    return false;
  }

  bool _stepChangeTakesUsCloser(int start, int destination, int stepChange){
    return (start + stepChange - destination).abs() < (start - destination).abs();
  }

  ///Returns a copy of tilesData
  List<List<Tile>> createCopyOfTilesData(){
    return tilesData.map((row) => row.map((tile) => tile).toList()).toList();
  }

  static List<List<Tile>> generateStandardStartingPosition(bool fromWhitesPerspective){
    List<List<Tile>> result = [];

    //Generate piece lists going from left to right then chose in function of row later
    List<Piece> lightPawns = List.generate(8, (index) => Pawn(true));
    List<Piece> darkPawns = List.generate(8, (index) => Pawn(false));
    List<Piece> lightMajors = [];
    lightMajors.add(Rook(true));
    lightMajors.add(Knight(true));
    lightMajors.add(Bishop(true));
    lightMajors.add(fromWhitesPerspective ? Queen(true) : King(true));
    lightMajors.add(fromWhitesPerspective ? King(true) : Queen(true));
    lightMajors.add(Bishop(true));
    lightMajors.add(Knight(true));
    lightMajors.add(Rook(true));
    List<Piece> darkMajors = [];
    darkMajors.add(Rook(false));
    darkMajors.add(Knight(false));
    darkMajors.add(Bishop(false));
    darkMajors.add(fromWhitesPerspective ? Queen(false) : King(false));
    darkMajors.add(fromWhitesPerspective ? King(false) : Queen(false));
    darkMajors.add(Bishop(false));
    darkMajors.add(Knight(false));
    darkMajors.add(Rook(false));

    //Generate color and piece data going from top left to bottom right
    bool onLight = true;
    for(int rowIndex = 0; rowIndex<8; rowIndex++){
      List<Tile> nextRow = [];
      for(int colIndex = 0; colIndex<8; colIndex++){
        Piece? piece;
        if(rowIndex == 0){
          if(fromWhitesPerspective){
            piece = darkMajors[colIndex];
          }else{
            piece = lightMajors[colIndex];
          }
        }
        if(rowIndex == 1){
          if(fromWhitesPerspective){
            piece = darkPawns[colIndex];
          }else{
            piece = lightPawns[colIndex];
          }
        }
        if(rowIndex == 7){
          if(fromWhitesPerspective){
            piece = lightMajors[colIndex];
          }else{
            piece = darkMajors[colIndex];
          }
        }
        if(rowIndex == 6){
          if(fromWhitesPerspective){
            piece = lightPawns[colIndex];
          }else{
            piece = darkPawns[colIndex];
          }
        }
        nextRow.add(Tile(onLight, colIndex, rowIndex, piece: piece));
        onLight = !onLight;
      }
      onLight = !onLight;
      result.add(nextRow);
    }
    return result;
  }

}
