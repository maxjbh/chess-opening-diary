import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_algorithm.dart';
import 'package:chess_opening_diary/chess_logic/piece_move_algorithms/piece_move_step.dart';
import 'package:chess_opening_diary/views/chessboard/move_instance.dart';
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

///Precondition : no king starts in check
class ChessboardControllerCubit extends Cubit<ChessboardControllerState> {

  ChessboardControllerCubit._({required this.size,  required this.tilesData, required this.fromWhitesPerspective, required this.whiteKingLocation, required this.blackKingLocation})
      : super(ChessboardControllerInitial());

  //Public factory method to handle calculations after instance is created
  static ChessboardControllerCubit newInstance({required size, List<List<Tile>>? tilesData, required fromWhitesPerspective}){
    List<List<Tile>> realTilesData = tilesData ?? generateStandardStartingPosition(fromWhitesPerspective);
    //Handle initialKingPositions
    Tile whiteKingPos = Tile(true, 0, 0);
    Tile blackKingPos = Tile(true, 0, 0);;
    for (List<Tile> row in realTilesData) {
      for (Tile tile in row) {
        if(tile.piece != null && tile.piece is King){
          if(tile.piece!.lightPiece){
            whiteKingPos = tile;
          }
          if(!tile.piece!.lightPiece){
            blackKingPos = tile;
          }
        }
      }
    }
    ChessboardControllerCubit result = ChessboardControllerCubit._(size: size, tilesData: realTilesData, whiteKingLocation: whiteKingPos, blackKingLocation: blackKingPos, fromWhitesPerspective: fromWhitesPerspective);
    return result;
  }

  ValueNotifier<int> boardPainterUpdateNotifier = ValueNotifier<int>(0);
  final double size;
  final bool fromWhitesPerspective;
  bool isWhitesTurn = true;
  ///This is a list of ROWS, so y is a coordinate of the first list
  final List<List<Tile>> tilesData;

  List<Tile> tilesWithMoveToIndicator = [];

  List<Tile> tilesWithCaptureCircle = [];

  ///A single memory slot as there can only ever be one
  Tile? passantablePieceContainer;

  ///The currently selected tile
  Tile? selectedTile;

  //Save king locations for fast Check checks
  Tile whiteKingLocation;
  Tile blackKingLocation;

  ///To make some calculations faster like verifying if we can't castle because we are in check
  bool isCheck = false;

  bool shouldRepaint = false;

  void handleClick(TapDownDetails pointerEvent){
    if(state is! CheckmateState){
      int realX = ((8*pointerEvent.localPosition.dx)/size).floor();
      int realY = ((8*pointerEvent.localPosition.dy)/size).floor();

      if(selectedTile != null){
        _moveToOrUnselect(realX, realY, selectedTile!);
      }else{
        _selectTileAt(realX, realY, isWhitesTurn);
      }
    }
  }

  ///Moves the selected piece to the square if we can go there, otherwise unselects the piece.
  ///selectedTile is the tile we are moving FROM.
  ///Handles castling.
  ///Handles if this move puts the other player in Check and if so, handles Checkmate.
  void _moveToOrUnselect(int x, int y, Tile selectedTile){
    Tile nextSquare = tilesData.elementAt(y).elementAt(x);
    bool isCheckmate = false;
    if(nextSquare.isPossibleMove || nextSquare.doDrawCaptureCircle){
      _handleMove(selectedTile, nextSquare, tilesData, true);
      //Handle isCheckMate calculation and set isCheck
      isCheckmate = _handleDoesMovePutInCheckMate();
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
    ChessboardControllerState stateToEmit = ChessboardNoSelectionState();
    if(isCheckmate){
      stateToEmit = CheckmateState();
    }
    shouldRepaint = true;
    emit(stateToEmit);
  }

  ///returns true if check mate.
  ///Its currently still the player who just put in check's turn
  bool _handleDoesMovePutInCheckMate(){
    //If not whites turn
    Tile kingLocation = whiteKingLocation;
    if(isWhitesTurn){
      kingLocation = blackKingLocation;
    }
    if(_checkIfOpposingSideCovers(kingLocation.x, kingLocation.y, !isWhitesTurn, tilesData)){
      isCheck = true;
      //First of all check if the king can just move somewhere
      Piece attackedKing = kingLocation.piece!;
      for(PieceMoveStep kingMove in attackedKing.pieceMoveAlgorithm.baseMoves){
        int nextKingX = kingLocation.x + kingMove.x;
        int nextKingY = kingLocation.y + kingMove.y;
        if(nextKingX >= 8 || nextKingX<0 || nextKingY >= 8 || nextKingY<0){
          continue;
        }
        Tile destinationTile = tilesData.elementAt(kingLocation.y + kingMove.y).elementAt(kingLocation.x + kingMove.x);
        Piece? destinationPiece = destinationTile.piece;
        if(destinationPiece==null || destinationPiece.lightPiece!=attackedKing.lightPiece){
          if(!_verifyIfHypotheticalMovePutsUsInCheck(kingLocation, destinationTile, attackedKing, kingMove)){
            return false;
          }
        }
      }
      //Then check if we can block or kill the piece without putting ourself in check
      //Ignore king for kill check as this has already been verified
      //Start by checking if there are multiple kingSeers, if so the game is over
      List<MoveInstance> kingSeersMoves = _getMovesThatCover(kingLocation, isWhitesTurn, tilesData, true);
      if(kingSeersMoves.length > 1){
        return true;
      }
      MoveInstance kingSeerMove = kingSeersMoves.first;
      //Check if we can kill the seer
      List<MoveInstance> attackerSeers = _getMovesThatCover(kingSeerMove.from, !isWhitesTurn, tilesData, true);
      for(MoveInstance attackerSeerMove in attackerSeers){
        if(!_verifyIfHypotheticalMovePutsUsInCheck(attackerSeerMove.from, attackerSeerMove.to, attackerSeerMove.movingPiece, attackerSeerMove.pieceMoveStep)){
          return false;
        }
      }
      //Check if we can block with any piece but king
      if(kingSeerMove.movingPiece is Pawn || kingSeerMove.movingPiece is Knight){
        return true;
      }
      return !_verifyIfWeCanBlockMove(kingSeerMove, tilesData);
    }else{
      isCheck = false;
    }
    return false;
  }

  //TODO add ignore king and use it from getMovesThatCover
  ///Checks moves that cover tile at x ; y,  if justWantToKnowIfCover then just return true as soon as the first move is found
  ///Otherwise return the list of moves
  dynamic _doesCoverCoreAlgo(
      int x,
      int y,
      bool asWhite,
      List<List<Tile>> tilesData,
      bool justWantToKnowIfCover
      ){
    List<MoveInstance> matchedMoves = [];
    Tile tileToCover = tilesData.elementAt(y).elementAt(x);
    int rowIndex = 0;
    for(List<Tile> row in tilesData){
      int colIndex = 0;
      for(Tile tile in row){
        Piece? piece = tile.piece;
        //If there is a piece and its of asWhite's color we can check if it covers tile at x, y
        if(piece != null && piece.lightPiece == asWhite){
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
                  asWhite,
                  piece,
                  tile,
                  tilesData,
                  _checkNextTile,
                  (int xFinish, int yFinish, bool asWhite, Piece activePiece){return xFinish == x && yFinish == y;},
                  (int lastX, int lastY, int iteratorCount){return !(lastX == x && lastY == y);},
                  0
              ) as bool;
              if(doesSeeTile){
                if(justWantToKnowIfCover){
                  return true;
                }
                matchedMoves.add(MoveInstance(from: tile, to: tileToCover, movingPiece: piece, pieceMoveStep: candidateMove));
              }
            }
          }else{
            if(piece is Pawn){
              for(PieceMoveStep move in algo.baseMoves){
                if(move.stepCapturableType == StepCapturableType.onlyCapturable){
                  PieceMoveStep realMove = Pawn.getRealCoordinateChangeForMove(move, asWhite, fromWhitesPerspective);
                  if(realMove.y + rowIndex == y && realMove.x + colIndex == x){
                    if(justWantToKnowIfCover){
                      return true;
                    }
                    matchedMoves.add(MoveInstance(from: tile, to: tileToCover, movingPiece: piece, pieceMoveStep: move));
                  }
                }
              }
            }else{
              for(PieceMoveStep move in algo.baseMoves){
                int nextX = colIndex + move.x;
                int nextY = rowIndex + move.y;
                if(nextX == x && nextY == y){
                  if(justWantToKnowIfCover){
                    return true;
                  }
                  matchedMoves.add(MoveInstance(from: tile, to: tileToCover, movingPiece: piece, pieceMoveStep: move));
                }
              }
            }
          }
        }
        colIndex++;
      }
      rowIndex++;
    }
    if(justWantToKnowIfCover){
      return matchedMoves.isNotEmpty;
    }
    return matchedMoves;
  }

  ///Gets moves that cover tile with asWhite's color, no verifications if the moves would put the moving player in check
  List<MoveInstance> _getMovesThatCover(Tile tile, bool asWhite, List<List<Tile>> tilesData, bool ignoreKing){
    return _doesCoverCoreAlgo(tile.x, tile.y, asWhite, tilesData, false) as List<MoveInstance>;
  }

  //TODO optimization here if i track piece locations by color
  ///Verify is opposing side of the mover can put a piece other than king in between from and to of moveToBlock.
  ///Precondition : moveToBlock is not from a Knight or a Pawn
  bool _verifyIfWeCanBlockMove(MoveInstance moveToBlock, List<List<Tile>> tilesData){
    //Calculate a and b if the move to block is along a diagonal, otherwise set constant x or constant y
    //Get smallest and biggest x and y's of the King-Attacker segment
    Tile attackerTile = moveToBlock.from;
    Tile attackedTile = moveToBlock.to;
    Tile tileWithSmallestX = moveToBlock.from;
    Tile tileWithBiggestX = moveToBlock.to;
    if(moveToBlock.to.x < moveToBlock.from.x){
      tileWithSmallestX = moveToBlock.to;
      tileWithBiggestX = moveToBlock.from;
    }
    int smallestY = min(attackerTile.y, attackedTile.y);
    int biggestY = max(attackerTile.y, attackedTile.y);
    int? moveXConstant;
    int? moveYConstant;
    int? moveLineA;
    int? moveLineB;
    if(tileWithSmallestX.x==tileWithBiggestX.x){
      moveXConstant = tileWithSmallestX.x;
    }else if(smallestY==biggestY){
      moveYConstant = smallestY;
    }else{
      moveLineA = tileWithSmallestX.y < tileWithBiggestX.y ? 1 : -1;
      moveLineB = tileWithSmallestX.y - moveLineA*tileWithSmallestX.x;
    }

    for(List<Tile> row in tilesData){
      for(Tile blockerTile in row){
        if(!(blockerTile.piece!=null && blockerTile.piece!.lightPiece!=moveToBlock.movingPiece.lightPiece && blockerTile.piece! is! King)){
          continue;
        }
        Piece candidateBlocker = blockerTile.piece!;
        //Calculate which directions are permitted 0 being up, up diagonally left and up diagonally right
        // ; and 7 being Left, up diagonally left and up
        int permittedDirectionsCompassValue = 0;
        if(moveYConstant != null){
          if(blockerTile.y == moveYConstant){
            continue;
          }
          permittedDirectionsCompassValue = 0;
          if(blockerTile.y > moveYConstant){
            permittedDirectionsCompassValue = 4;
          }
        }else if(moveXConstant != null){
          if(blockerTile.x == moveXConstant){
            continue;
          }
          permittedDirectionsCompassValue = 2;
          if(blockerTile.x > moveXConstant){
            permittedDirectionsCompassValue = 6;
          }
        } else{
          int yOfXEqualsBlockerX = moveLineA!*blockerTile.x + moveLineB!;
          if(yOfXEqualsBlockerX == blockerTile.y){
            continue;
          }
          if(moveLineA == 1){
            if(yOfXEqualsBlockerX > blockerTile.y){
              permittedDirectionsCompassValue = 7;
            }else{
              permittedDirectionsCompassValue = 3;
            }
          }else{
            if(yOfXEqualsBlockerX > blockerTile.y){
              permittedDirectionsCompassValue = 5;
            }else{
              permittedDirectionsCompassValue = 1;
            }
          }
        }
        for(PieceMoveStep candiateBlockerMoveStep in candidateBlocker.pieceMoveAlgorithm.baseMoves){
          PieceMoveStep realBlockerMoveStep = candiateBlockerMoveStep;
          if(candidateBlocker is Pawn){
            realBlockerMoveStep = Pawn.getRealCoordinateChangeForMove(candiateBlockerMoveStep, !moveToBlock.movingPiece.lightPiece, fromWhitesPerspective);
            if(!_pawnMoveIsValid(candiateBlockerMoveStep, realBlockerMoveStep, candidateBlocker, blockerTile.x, blockerTile.y)){
              continue;
            }
          }
          //Check that move validates compass direction for any piece type
          if(!realBlockerMoveStep.validatesCompassDirection(permittedDirectionsCompassValue)){
            continue;
          }
          if(candidateBlocker.pieceMoveAlgorithm.isRepeatable){
            //Continue if the move is on a diagonal to a diagonal of differnt color
            if(realBlockerMoveStep.x.abs()==1 && realBlockerMoveStep.y.abs()==1 && moveLineA!=null && blockerTile.lightTile!=attackerTile.lightTile){
              continue;
            }
            //Coordinates of the intersection of the blocker moved played the amount of times necessary to get there
            int xIntersection = 0;
            int yIntersection = 0;
            //In function of Attacker-Attacked segment type continue or add to moves to test and continue
            if(moveYConstant != null){
              int blockerIntersectionX = blockerTile.x + realBlockerMoveStep.x*(moveYConstant - blockerTile.y).abs();
              if(blockerIntersectionX >= tileWithBiggestX.x || blockerIntersectionX <= tileWithSmallestX.x){
                continue;
              }
              xIntersection = blockerIntersectionX;
              yIntersection = moveYConstant;
            } else if(moveXConstant !=null){
              int blockerIntersectionY = blockerTile.y + realBlockerMoveStep.y*(moveXConstant - blockerTile.x).abs();
              if(blockerIntersectionY >= biggestY || blockerIntersectionY <= smallestY){
                continue;
              }
              xIntersection = moveXConstant;
              yIntersection = blockerIntersectionY;
            } else{
              // the Attacker-Attacked segment is a diagonal
              if(realBlockerMoveStep.x == 0){
                if(blockerTile.x <= tileWithSmallestX.x || blockerTile.x >= tileWithBiggestX.x){
                  continue;
                }
                xIntersection = blockerTile.x;
                yIntersection = blockerTile.x*moveLineA! + moveLineB!;
              }else if(realBlockerMoveStep.y == 0){
                if(blockerTile.y <= smallestY || blockerTile.y >= biggestY){
                  continue;
                }
                xIntersection = (blockerTile.y - moveLineB!)*moveLineA!;
                yIntersection = blockerTile.y;
              }else{
                //Blocker is moving along a diagonal
                int amountOfStepsToReachLine = (moveLineA!*blockerTile.x + moveLineB! - blockerTile.y)/2 as int;
                xIntersection = blockerTile.x + realBlockerMoveStep.x*amountOfStepsToReachLine;
                if(xIntersection <= tileWithSmallestX.x || xIntersection >= tileWithBiggestX.x){
                  continue;
                }
                yIntersection = blockerTile.y + realBlockerMoveStep.y*amountOfStepsToReachLine;
                if(yIntersection <= smallestY || yIntersection >= biggestY){
                  continue;
                }
              }
            }
            //From here we have the coordinates of an intersection with the Attacker-Attacked segment, see if no pieces are blocking
            bool canReachIntersection = _repeatDirectionFromTile(
              blockerTile,
              realBlockerMoveStep,
              tilesData,
              _checkNextTile,
              (int xFinish, int yFinish, bool asWhite, Piece activePiece){return xFinish == xIntersection && yFinish == yIntersection;},
              (int lastX, int lastY, int iteratorCount){return !(lastX == xIntersection && lastY == yIntersection);}
            ) as bool;
            if(!canReachIntersection){
              continue;
            }
            if(!_verifyIfHypotheticalMovePutsUsInCheck(blockerTile, tilesData.elementAt(yIntersection).elementAt(xIntersection), blockerTile.piece!, realBlockerMoveStep)){
              return true;
            }
            //Continue so we don't have to wrap non repeatbale step handling in an if
            continue;
          }
          //From here we know the move is from a knight or a pawn and the move takes us in the correct general direction
          int blockerNextX = blockerTile.x + realBlockerMoveStep.x;
          int blockerNextY = blockerTile.y + realBlockerMoveStep.y;
          if(blockerNextX >= 8 || blockerNextX<0 || blockerNextY >= 8 || blockerNextY<0){
            continue;
          }
          if(moveXConstant != null){
            if(blockerNextX != moveXConstant || blockerNextY >= biggestY || blockerNextY <= smallestY){
              continue;
            }
          }else if(moveYConstant != null){
            if(blockerNextY != moveYConstant || blockerNextX >= tileWithBiggestX.x || blockerNextX <= tileWithSmallestX.x){
              continue;
            }
          }else{
            //Attacker-Attacked is a diagonal, check that we end up on line
            if(!(blockerNextY == moveLineA!*blockerNextX + moveLineB!)){
              continue;
            }
            //Check that we are on segment
            if(blockerNextX <= tileWithSmallestX.x || blockerNextX >= tileWithBiggestX.x){
              continue;
            }
            if(blockerNextY <= smallestY || blockerNextY >= biggestY){
              continue;
            }
          }
          //If it is a pawn, and an en-passant, handle validation
          if(blockerTile.piece! is Pawn && realBlockerMoveStep.stepCapturableType == StepCapturableType.onlyCapturable){
            //Handle en passant
            if(!_enPassantMoveIsValid(tilesData.elementAt(blockerNextY).elementAt(blockerNextX), blockerTile, blockerTile.piece!, realBlockerMoveStep)){
              continue;
            }
            return true;
          }
          //We know that the knight or pawn move lands on our line, verify if we would be in check
          if(!_verifyIfHypotheticalMovePutsUsInCheck(blockerTile, tilesData.elementAt(blockerNextY).elementAt(blockerNextX), blockerTile.piece!, realBlockerMoveStep)){
            return true;
          }
        }
      }
    }
    //Made it to end without finding a block so return false
    return false;
  }

  ///Handles move, tiles can be from main position or a hypothetical one, if so any calculations that involve future moves are ignored (example, is passantable)
  ///Precondition : from contains a piece
  void _handleMove(Tile from, Tile to, List<List<Tile>> inTilesData, bool forRealPosition){
    Piece movingPiece = from.piece!;
    //Handle en-passant and castling
    Tile? passantablePieceContainerToUse = forRealPosition ?
      passantablePieceContainer
        :
      (passantablePieceContainer==null ? null : inTilesData.elementAt(passantablePieceContainer!.y).elementAt(passantablePieceContainer!.x));
    _handleEnPassantForMove(to, movingPiece, passantablePieceContainerToUse, forRealPosition);
    _handleCastleMove(movingPiece, to.x, to.y, inTilesData);
    to.setPiece(movingPiece);
    from.setPiece(null);
    //Anything after this if involves future moves
    if(!forRealPosition){
      return;
    }
    //Handle resetting king location
    if(movingPiece is King){
      if(isWhitesTurn){
        whiteKingLocation = to;
      }else{
        blackKingLocation = to;
      }
    }
    //Set hasMoved
    movingPiece.hasMoved = true;
  }

  ///Extracted as the order of operations is important.
  ///For hypothetical position only play move if it is a en-passant, no need to do other operations.
  ///passantablePieceContainer is a prop in case we are using hypothetical position.
  ///1. Identify if our move is a take en-passant, if so remove the piece then unset passantablePieceContainer to not get a null Pawn in the next step
  ///2. Always unset passantablePieceContainer on any move because we know a piece is only passantable for one turn
  ///3. After handling potential previous en-passant see if the next move is creating a new passantable piece
  void _handleEnPassantForMove(Tile nextSquare, Piece? movingPiece, Tile? passantablePieceContainer, bool forRealPosition){
    //Check if we are taking passantable piece so we can handle it before unsetting
    Piece? attackedPiece = nextSquare.piece;
    if(attackedPiece == null && nextSquare.doDrawCaptureCircle){
      passantablePieceContainer?.setPiece(null);
      if(forRealPosition){
        this.passantablePieceContainer = null;
      }
    }
    //Leave function if hypothetical position
    if(!forRealPosition){
      return;
    }
    //Unset passantable piece before potentially setting new one
    if(this.passantablePieceContainer != null){
      (this.passantablePieceContainer!.piece as Pawn).isPassantable = false;
      this.passantablePieceContainer = null;
    }
    //Set isPassantable
    if(movingPiece != null && (movingPiece is Pawn) && !movingPiece.hasMoved && nextSquare.isPossibleMove && (nextSquare.y - selectedTile!.y).abs() == 2){
      movingPiece.isPassantable = true;
     this.passantablePieceContainer = nextSquare;
    }
  }

  ///1. Checks if the move is a castle move.
  ///2. Handle moving the rook during the move
  void _handleCastleMove(Piece movingPiece, int nextX, int nextY, List<List<Tile>> tilesData){
    if(movingPiece is! King || movingPiece.hasMoved || (nextX!=2 && nextX!=6)){
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

  ///Verifies in the case the pawnMove's y==2
  bool _pawnMoveIsValid(PieceMoveStep unconvertedPawnMove, PieceMoveStep convertedPawnMove, Piece pawn, int pawnX, int pawnY){
    if(unconvertedPawnMove.y == 2){
      if(pawn.hasMoved){
        return false;
      }
      //Get piece at move/2 if present then we can't jump over it
      Piece? blockingPiece = tilesData.elementAt(pawnY + (convertedPawnMove.y/2 as int)).elementAt(pawnX).piece;
      if(blockingPiece != null){
        return false;
      }
    }
    return true;
  }

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
        _repeatDirection(x, y, pieceMoveStep, asWhite, piece, selectedTile, tilesData, _checkNextTileForActivePieceMoveIndicator, null, null, 0);
      }else{
        PieceMoveStep realMove = pieceMoveStep;
        if(piece is Pawn){
          realMove = Pawn.getRealCoordinateChangeForMove(pieceMoveStep, asWhite, fromWhitesPerspective);
          if(!_pawnMoveIsValid(pieceMoveStep, realMove, piece, x, y)){
            continue;
          }
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
        _checkNextTileForActivePieceMoveIndicator(nextX, nextY, asWhite, piece, realMove, selectedTile, tilesData);
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
      Tile activeTile,
      List<List<Tile>> tilesData,
      bool Function(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep step, Tile startingTile, List<List<Tile>> tilesData) onNextTileDoContinue,
      dynamic Function(int xFinish, int yFinish, bool asWhite, Piece activePiece)? onFinish,
      bool Function(int nextX, int nextY, int iteratorCount)? extraCanContinueCheck,
      int iteratorCount
      ){
    int nextX = x + step.x;
    int nextY = y + step.y;
    bool canContinue = onNextTileDoContinue(nextX, nextY, asWhite, activePiece, step, activeTile, tilesData);
    if(canContinue && extraCanContinueCheck != null){
      canContinue = extraCanContinueCheck(nextX, nextY, iteratorCount);
    }
    if(canContinue){
      return _repeatDirection(nextX, nextY, step, asWhite, activePiece, activeTile, tilesData,onNextTileDoContinue, onFinish, extraCanContinueCheck, iteratorCount++);
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
  ///Condensed version of _repeatDirection
  dynamic _repeatDirectionFromTile(
      Tile from,
      PieceMoveStep step,
      List<List<Tile>> tilesData,
      bool Function(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep step, Tile startingTile, List<List<Tile>> tilesData) onNextTileDoContinue,
      dynamic Function(int xFinish, int yFinish, bool asWhite, Piece activePiece)? onFinish,
      bool Function(int nextX, int nextY, int iteratorCount)? extraCanContinueCheck,
      ){
    return _repeatDirection(
        from.x,
        from.y,
        step,
        from.piece!.lightPiece,
        from.piece!,
        from,
        tilesData,
        onNextTileDoContinue,
        onFinish,
        extraCanContinueCheck,
        0
    );
  }

  ///Checks if next tile is edge or a piece, no extra code
  bool _checkNextTile(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep step, Tile startingTile, List<List<Tile>> tilesData){
    if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
      return false;
    }
    Tile nextTile = tilesData.elementAt(nextY).elementAt(nextX);
    Piece? nextTilesPiece = nextTile.piece;
    return nextTilesPiece==null;
  }

  /*bool _checkNextTileIgnoreCurrentPlayersKing(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep step){
    if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
      return false;
    }
    Tile nextTile = tilesData.elementAt(nextY).elementAt(nextX);
    Piece? nextTilesPiece = nextTile.piece;
    if(nextTilesPiece != null && nextTilesPiece is King && nextTilesPiece.lightPiece == isWhitesTurn){
      return true;
    }
    return nextTilesPiece==null;
  }*/

  //TODO optimization, create a copy earlyer , modify it to check then unmodify, but fuck i could have just dpne that to tilesData
  //TODO optimization, create shourtcut lists for all tiles containing white pieces and black pieces
  ///Creates copies of tilesData, from and to to play a hypothetical move to test if activePiece's side would be in check
  ///Precondition : move is a valid move without counting checks
  bool _verifyIfHypotheticalMovePutsUsInCheck(Tile from, Tile to, Piece activePiece, PieceMoveStep move){
    //Construct new tiles data
    List<List<Tile>> hypoTilesData = createCopyOfTilesData();
    Tile hypoFrom = hypoTilesData.elementAt(from.y).elementAt(from.x);
    Tile hypoTo = hypoTilesData.elementAt(to.y).elementAt(to.x);
    //If we are moving king set new kingX and kingY instead of using king location
    int kingX = (activePiece.lightPiece ? whiteKingLocation.x : blackKingLocation.x);
    int kingY = (activePiece.lightPiece ? whiteKingLocation.y : blackKingLocation.y);
    if(activePiece is King){
      kingX = to.x;
      kingY = to.y;
    }
    //Set hypoTo isCapturable if pawn attack as this is needed to handle en-passant
    if((activePiece is Pawn) && (move.stepCapturableType == StepCapturableType.onlyCapturable)){
      hypoTo.doDrawCaptureCircle = true;
    }
    //Play the hypothetical move
    _handleMove(hypoFrom, hypoTo, hypoTilesData, false);
    //Verify if we are in check
    return _checkIfOpposingSideCovers(kingX, kingY, activePiece.lightPiece, hypoTilesData);

  }

  ///Returns true if the move has a valid en-passant-able piece under it and if the move wouldn't put us in check.
  ///Precondition : the move is a en-passant (only capture-able and null piece at destination)
  bool _enPassantMoveIsValid(Tile destinationTile, Tile fromTile, Piece pawn, PieceMoveStep move){
    Tile candidate;
    Piece? candidatePiece;
    if(pawn.lightPiece != fromWhitesPerspective){
      //look at nextY - 1
      candidate = tilesData.elementAt(destinationTile.y - 1).elementAt(destinationTile.x);
      candidatePiece = candidate.piece;
    }else{
      //look at nexty + 1
      candidate = tilesData.elementAt(destinationTile.y + 1).elementAt(destinationTile.x);
      candidatePiece = candidate.piece;
    }
    if(candidatePiece != null && candidatePiece is Pawn && candidatePiece.lightPiece != pawn.lightPiece && candidatePiece.isPassantable){
      if(!_verifyIfHypotheticalMovePutsUsInCheck(fromTile, destinationTile, pawn, move)){
        return true;
      }
    }
    return false;
  }

  ///checks if a move has a piece, sets the tile isMovable and doDrawCaptureCircle booleans, if not null.
  ///Returns a bool that is true if no same-sided piece was found and we still haven't fallen of the board.
  ///Handles king not being able to go into check
  ///Handles en passant
  ///Handles move doesn't put moving player in check
  bool _checkNextTileForActivePieceMoveIndicator(int nextX, int nextY, bool asWhite, Piece activePiece, PieceMoveStep move, Tile activeTile, List<List<Tile>> tilesData){
    if(nextX >= 8 || nextX<0 || nextY >= 8 || nextY<0){
      return false;
    }
    Tile nextTile = tilesData.elementAt(nextY).elementAt(nextX);
    Piece? nextTilesPiece = nextTile.piece;
    if(nextTilesPiece==null){
      if(move.stepCapturableType != StepCapturableType.onlyCapturable){
        if(!_verifyIfHypotheticalMovePutsUsInCheck(activeTile, nextTile, activePiece, move)){
          tilesWithMoveToIndicator.add(nextTile);
          nextTile.isPossibleMove = true;
        }
        return true;
      }
      if(activePiece is Pawn && move.stepCapturableType == StepCapturableType.onlyCapturable){
        //Handle en passant
        if(_enPassantMoveIsValid(nextTile, activeTile, activePiece, move)){
          tilesWithCaptureCircle.add(nextTile);
          nextTile.doDrawCaptureCircle = true;
        }
      }
      return false;
    }
    if(nextTilesPiece.lightPiece!=asWhite && move.stepCapturableType != StepCapturableType.nonCapturable){
      if(!_verifyIfHypotheticalMovePutsUsInCheck(activeTile, nextTile, activePiece, move)){
        tilesWithCaptureCircle.add(nextTile);
        nextTile.doDrawCaptureCircle = true;
      }
    }
    return false;
  }

  ///Precondition, the piece is a king
  bool _checkIfWeCanCastleFrom(int x, int y, bool asWhite, King activePiece, PieceMoveStep move){
    //TODO add can't castle out of check
    if(activePiece.hasMoved || isCheck){
      return false;
    }
    PieceMoveStep convertedToOneStep = PieceMoveStep(x: (move.x/2) as int, y: move.y, stepCapturableType: move.stepCapturableType);
    return _repeatDirection(
        x,
        y,
        convertedToOneStep,
        asWhite,
        activePiece,
        tilesData.elementAt(y).elementAt(x),
        tilesData,
        _checkNextTile,
        (xFinish, yFinish, asWhite, activePiece){
          Piece? pieceReached = tilesData.elementAt(yFinish).elementAt(xFinish).piece;
          return pieceReached!=null && pieceReached is Rook && pieceReached.lightPiece==asWhite && !pieceReached.hasMoved;
        },
        (int nextX, int nextY, int iteratorCount){
          //only check on 0 as last tile gets verified for check anyway
          if(iteratorCount < 1){
            return !_checkIfOpposingSideCovers(nextX, nextY, asWhite, tilesData);
          }
          return true;
        },
        0
    );
  }

  ///Returns true if the opposing side does cover this square.
  ///Including the enemy king even if it would be putting itself in check.
  bool _checkIfOpposingSideCovers(
      int x,
      int y,
      bool asWhite,
      List<List<Tile>> tilesData
    ){
    return _doesCoverCoreAlgo(x, y, !asWhite, tilesData, true) as bool;
  }

  bool _stepChangeTakesUsCloser(int start, int destination, int stepChange){
    return (start + stepChange - destination).abs() < (start - destination).abs();
  }

  ///Returns a copy of tilesData
  List<List<Tile>> createCopyOfTilesData(){
    return tilesData.map((row) => row.map((tile) => tile.createCopy()).toList()).toList();
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
