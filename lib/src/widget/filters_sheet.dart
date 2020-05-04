import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mikack/mikack.dart';

import '../blocs.dart';
import '../widget/tag.dart';
import '../values.dart';

const _tagFontSize = 10.8;

class FiltersSheet extends StatelessWidget {
  final BuildContext appContext;

  FiltersSheet({@required this.appContext});

  @override
  Widget build(BuildContext context) {
    var tagModels = tags();
    return BlocBuilder<FiltersBloc, FiltersState>(
      bloc: appContext.bloc<FiltersBloc>(),
      builder: (ctx, state) {
        var castedState = state as FiltersLoadedState;

        var includesTags = tagModels
            .map((t) => Tag(
                  t.value,
                  t.name,
                  fontSize: _tagFontSize,
                  stateful: false,
                  selected: castedState.includes.contains(t.value),
                  stateFixed:
                      !castedState.isAllowNsfw && t.value == vNsfwTagIntValue,
                  stateFixedReason: vAllowNsfwHint,
                  onTap: (value, selected) {
                    FiltersUpdateAction action;
                    if (selected)
                      action = FiltersUpdateAction.added;
                    else
                      action = FiltersUpdateAction.removed;
                    appContext.bloc<FiltersBloc>().add(FiltersUpdatedEvent(
                          action: action,
                          value: value,
                          from: FiltersUpdateFrom.includes,
                          historiesBloc: appContext?.bloc<LibrariesBloc>(),
                        ));
                  },
                ))
            .toList();
        var excludesTags = tagModels
            .map((t) => Tag(
                  t.value,
                  t.name,
                  fontSize: _tagFontSize,
                  stateful: false,
                  selected: castedState.excludes.contains(t.value),
                  stateFixed:
                      !castedState.isAllowNsfw && t.value == vNsfwTagIntValue,
                  stateFixedReason: vAllowNsfwHint,
                  onTap: (value, selected) {
                    FiltersUpdateAction action;
                    if (selected)
                      action = FiltersUpdateAction.added;
                    else
                      action = FiltersUpdateAction.removed;
                    appContext.bloc<FiltersBloc>().add(FiltersUpdatedEvent(
                          action: action,
                          value: value,
                          from: FiltersUpdateFrom.excludes,
                          historiesBloc: appContext?.bloc<LibrariesBloc>(),
                        ));
                  },
                ))
            .toList();
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                child: Text('来源过滤', style: TextStyle(color: Colors.black)),
              ),
              // 标签过滤
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '包含的标签',
                      style: TextStyle(fontSize: 14.5, color: Colors.grey[700]),
                    ),
                    Divider(),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      alignment: WrapAlignment.start,
                      runSpacing: 10,
                      children: includesTags,
                    ),
                    SizedBox(height: 25),
                    Text(
                      '排除的标签',
                      style: TextStyle(fontSize: 14.5, color: Colors.grey[700]),
                    ),
                    Divider(),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      alignment: WrapAlignment.start,
                      runSpacing: 10,
                      children: excludesTags,
                    ),
                  ],
                ),
              ),
              Center(
                child: Text('部分来源可能存在多个标签',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
