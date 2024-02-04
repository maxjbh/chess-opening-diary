import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'expandable_checkboxs_state.dart';

class ExpandableCheckboxesCubit extends Cubit<ExpandableCheckboxesState> {
  ExpandableCheckboxesCubit(List<String> initialSelection) : super(ExpandableCheckboxesInitial()){
    this.currentSelection = initialSelection;
  }

  void resetState(List<String> currentSelection){
    this.currentSelection = currentSelection;
    emit(ExpandableCheckboxesInitial());
  }

  List<String> currentSelection = [];

  void changingSelected({required List<String> newSelection}){
    currentSelection = newSelection;
    emit(ExpandableCheckboxesChanged(newSelection: newSelection));
  }
  void addOrRemoveToSelection(String s){
    if(currentSelection.contains(s)){
      currentSelection.remove(s);
    }else{
      currentSelection.add(s);
    }
  }

  void addOrRemoveToSelectionAndEmit(String s){
    if(currentSelection.contains(s)){
      currentSelection.remove(s);
    }else{
      currentSelection.add(s);
    }
    emit(ExpandableCheckboxChanged(s));
  }


}
