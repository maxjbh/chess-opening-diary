import 'package:chess_opening_diary/logIn/user_app_bar.dart';
import 'package:chess_opening_diary/views/chessboard/chessboard.dart';
import 'package:chess_opening_diary/views/chessboard/chessboard_controller_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/global_tools.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    ChessboardControllerCubit chessboardControllerCubit = ChessboardControllerCubit(size: 800.0, fromWhitesPerspective: true);
    return WillPopScope(
      onWillPop: () => GlobalTools.onFinalBackPressed(context),
      child: SafeArea(
        child: Scaffold(
          appBar: createAppBar(context),
          body: BlocProvider(
            create: (context) => chessboardControllerCubit,
            child: Chessboard(controllerCubit: chessboardControllerCubit,),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget createAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(GlobalTools.appTitle,
            style: TextStyle(fontSize: GlobalTools.textSizeLarge),
          ),
          Row(
            children: const [
              UserAppBar(
                /*onHomeButtonPressed: () async {
                  if (!BlocProvider.of<MyFormController>(context).poppingPage) {
                    BlocProvider.of<MyFormController>(context).poppingPage =
                    true;
                    await BlocProvider.of<MyFormController>(context)
                        .synchronizeForm();
                    BlocProvider.of<MyFormController>(context).poppingPage =
                    false;
                  }
                },*/
              ),
            ],
          ),
        ],
      ),
    );
  }


}
