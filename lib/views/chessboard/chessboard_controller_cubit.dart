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

  final ValueNotifier<int> boardPainterUpdateNotifier = ValueNotifier<int>(0);
  final double size;
  final bool fromWhitesPerspective;
  ///This is a list of ROWS, so y is a coordinate of the first list
  final List<List<Tile>> tilesData;

  ///So that we can quickly revert is the move isn't performed
  List<List<Tile>>? tilesDataBeforeSelect;

  //TODO handle pieces not being able to reveal a check on own king

  ///Constructs new tilesData containing possible moves for this piece
  void selectTileAt(int x, int y, bool asWhite){
    Tile selectedTile = tilesData.elementAt(y).elementAt(x);
    Piece? piece = selectedTile.piece;
    if(piece==null || piece.lightPiece!=asWhite){
      return;
    }
    //save a copy in case the move gets cancelled
    tilesDataBeforeSelect = createCopyOfTilesData();
    selectedTile.isSelected = true;
    PieceMoveAlgorithm pieceMoveAlgorithm = piece.pieceMoveAlgorithm;
    for(PieceMoveStep pieceMoveStep in pieceMoveAlgorithm.baseMoves){
      if(pieceMoveAlgorithm.isRepeatable){
        _repeatDirection(x, y, pieceMoveStep, asWhite, piece, _checkNextTileForActivePieceMoveIndicator, null, null, 0);
      }else{
        PieceMoveStep realMove = pieceMoveStep;
        if(piece is Pawn){
          if(pieceMoveStep.y == 2 && piece.hasMoved){
            break;
          }
          realMove = Pawn.getRealCoordinateChangeForMove(pieceMoveStep, asWhite, fromWhitesPerspective);
        }
        if(piece is King){
          if(pieceMoveStep.x.abs() == 2){
            if(!_checkIfWeCanCastleFrom(x, y, asWhite, piece, pieceMoveStep)){
              break;
            }
          }
        }
        int nextX = x + realMove.x;
        int nextY = y + realMove.y;
        _checkNextTileForActivePieceMoveIndicator(nextX, nextY, asWhite, piece, realMove);
      }
    }
    emit(PieceSelectedState());
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
      bool Function(int nextX, int nextY, int iteratorCount)? extraEndIterationCheck,
      int iteratorCount
      ){
    int nextX = x + step.x;
    int nextY = y + step.y;
    bool canContinue = onNextTileDoContinue(nextX, nextY, asWhite, activePiece, step);
    if(extraEndIterationCheck != null){
      canContinue = extraEndIterationCheck(nextX, nextY, iteratorCount);
    }
    if(canContinue){
      _repeatDirection(nextX, nextY, step, asWhite, activePiece, onNextTileDoContinue, onFinish, extraEndIterationCheck, iteratorCount++);
    }else{
      if(onFinish != null){
        //Only call onFinish with nextX and nextY if there are still on the board,
        // otherwise call with the last tile that wasn't empty
        // (so that we don't also have to do checks in the passed onFinish function)
        if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
          return onFinish(x, y, asWhite, activePiece);
        }else{
          return onFinish(nextX, nextY, asWhite, activePiece);
        }
      }
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

  
  ///checks if a move has a piece, sets the tile isMovable and doDrawCaptureCircle booleans, if not null.
  ///Returns a bool that is true if no same-sided piece was found and we still haven't fallen of the board.
  ///Handles king not being able to go into check
  bool _checkNextTileForActivePieceMoveIndicator(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep move){
    if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
      return false;
    }
    Tile nextTile = tilesData.elementAt(nextY).elementAt(nextX);
    Piece? nextTilesPiece = nextTile.piece;
    //Check that king isn't moving into a check
    if(activePiece is King){
      bool opposingCanSeeNextTile = _checkIfApposingSideCovers(nextX, nextY, asWhite);
      if(opposingCanSeeNextTile){
        //Note the value of this return isn't important, its just to quit the function
        return false;
      }
    }
    if(nextTilesPiece==null){
      if(move.stepCapturableType != StepCapturableType.onlyCapturable){
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
          nextTile.doDrawCaptureCircle = true;
        }
      }
      return false;
    }
    if(nextTilesPiece.lightPiece!=asWhite && move.stepCapturableType != StepCapturableType.nonCapturable){
      nextTile.doDrawCaptureCircle = true;
    }
    return false;
  }

  ///Precondition, the piece is a king
  bool _checkIfWeCanCastleFrom(int x, int y, bool asWhite, King activePiece, PieceMoveStep move){
    if(activePiece.hasMoved){
      return false;
    }
    PieceMoveStep convertedToOneStep = PieceMoveStep(x: (x/2) as int, y: y, stepCapturableType: move.stepCapturableType);
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
            return !_checkIfApposingSideCovers(nextX, nextY, asWhite);
          }
          return true;
        },
        0
    );
  }

  ///Returns true if the opposing side does cover this square
  bool _checkIfApposingSideCovers(int x, int y, bool asWhite){
    int rowIndex = 0;
    int colIndex = 0;
    for(List<Tile> row in tilesData){
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
                if((x - colIndex).abs() == (y - rowIndex).abs() && stepChangeTakesUsCloser(colIndex, x, move.x) && stepChangeTakesUsCloser(rowIndex, y, move.y)){
                  candidateMove = move;
                  break;
                }
              }else{
                if(move.x == 0){
                  //Vertical move along y axis, so x needs to be same, and we need to be heading in correct direction along y axis
                  if(x == colIndex && stepChangeTakesUsCloser(rowIndex, y, move.y)){
                    candidateMove = move;
                    break;
                  }
                }else{
                  //move.y == 0, horizontal move, y needs to be the same, and we need to be heading in correct direction along x axis
                  if(y == rowIndex && stepChangeTakesUsCloser(colIndex, x, move.x)){
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
                  asWhite,
                  piece,
                  _checkNextTile,
                  (int xFinish, int yFinish, bool asWhite, Piece activePiece){return xFinish == x && yFinish == y;},
                  (int lastX, int lastY, int iteratorCount){return lastX != x && lastY != y;},
                  0
              );
              if(doesSeeTile){
                return doesSeeTile;
              }
            }
          }else{
            if(piece is Pawn){
              for(PieceMoveStep move in algo.baseMoves){
                if(move.stepCapturableType == StepCapturableType.onlyCapturable){
                  PieceMoveStep realMove = Pawn.getRealCoordinateChangeForMove(move, asWhite, fromWhitesPerspective);
                  if(realMove.y + rowIndex == x && realMove.x + colIndex == y){
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

  bool stepChangeTakesUsCloser(int start, int destination, int stepChange){
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
        nextRow.add(Tile(onLight, piece: piece));
        onLight = !onLight;
      }
      onLight = !onLight;
      result.add(nextRow);
    }
    return result;
  }

}
