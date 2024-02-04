import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

import '../../utils/button_stuff/used_icons.dart';
import '../model/user.dart';
import 'log_in_cubit.dart';

///User info in its simplist format, user, connected light, optional small login button
class UserAppBar extends StatelessWidget {
  final Function? onHomeButtonPressed;

  const UserAppBar({Key? key, this.onHomeButtonPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? user = BlocProvider.of<LogInCubit>(context).user;
    String tooltipMessage = 'Not logged in';
    String userName = 'Guest';
    Color blipColor = Colors.red;
    if (user != null) {
      userName = user.email;
      if (user.hasLoggedIn) {
        blipColor = Colors.green;
        tooltipMessage = 'Connected';
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          userName,
          style: TextStyle(
            fontSize: 16.0,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          child: Tooltip(
              message: tooltipMessage,
              child: BlocBuilder<LogInCubit, LogInState>(
                buildWhen: (prev, nxt) {
                  return nxt is LogInExpiredState;
                },
                builder: (context, state) {
                  if (state is LogInExpiredState) {
                    blipColor = Colors.red;
                  }
                  return FaIcon(FontAwesomeIcons.solidCircle,
                      color: blipColor, size: 18.0);
                },
              )),
        ),
        (ResponsiveWrapper.of(context).isLargerThan(MOBILE)
            ? UsedIcons.homeButton(context, onPressed: onHomeButtonPressed)
            : Container()),
        (ResponsiveWrapper.of(context).isLargerThan(MOBILE)
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
                child: Tooltip(
                  message: 'Settings',
                  child: UsedIcons.buildSettingsIconButton(context),
                ),
              )
            : Container()),
      ],
    );
  }
}
