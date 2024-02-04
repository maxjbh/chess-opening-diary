

part of 'expandable_checkboxs_cubit.dart';


@immutable
abstract class ExpandableCheckboxesState {}

class ExpandableCheckboxesInitial extends ExpandableCheckboxesState {}

class ExpandableCheckboxesChanged extends ExpandableCheckboxesState {
  final List<String> newSelection;
  ExpandableCheckboxesChanged({required this.newSelection}):super();
}
class ExpandableCheckboxChanged extends ExpandableCheckboxesState {
  final String checkboxName;
  ExpandableCheckboxChanged(this.checkboxName):super();
}