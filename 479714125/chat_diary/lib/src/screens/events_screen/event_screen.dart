import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/event_model.dart';
import '../../models/page_model.dart';
import 'cubit/cubit.dart';
import 'widgets/app_bars.dart';
import 'widgets/event_input_field.dart';
import 'widgets/event_list.dart';

class EventScreen extends StatefulWidget {
  final PageModel page;
  const EventScreen({
    Key? key,
    required this.page,
  }) : super(key: key);

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final List<EventModel> _favoriteEvents = <EventModel>[];
  final FocusNode _inputNode = FocusNode();
  final TextEditingController _inputController = TextEditingController();
  late final EventScreenCubit cubit;

  @override
  void initState() {
    cubit = BlocProvider.of<EventScreenCubit>(context);
    super.initState();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventScreenCubit, EventScreenState>(
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: state.containsSelected
              ? MessageClickedAppBar(
                  addToFavorites: _addToFavorites,
                  findEventToEdit: _findEventToEdit,
                  copySelectedEvents: _copySelectedEvents,
                ) as PreferredSizeWidget
              : DefaultAppBar(
                  title: widget.page.name,
                ),
          body: GestureDetector(
            onTap: _hideKeyboard,
            child: Column(
              children: [
                Expanded(
                  child: EventList(),
                ),
                EventInputField(
                  editEvent: _editEvent,
                  inputController: _inputController,
                  inputNode: _inputNode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copySelectedEvents() async {
    final cubit = BlocProvider.of<EventScreenCubit>(context);
    final eventsToCopy = cubit.copySelectedEvents();
    if (eventsToCopy != '') {
      await Clipboard.setData(ClipboardData(text: eventsToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('Text copied to clipboard'),
        ),
      );
    }
    cubit.toggleAllSelected();
  }

  void _findEventToEdit() {
    final cubit = BlocProvider.of<EventScreenCubit>(context);
    final index = cubit.findSelectedEventIndex();
    _showKeyboard();
    cubit.setIsEditing();
    _inputController.text = cubit.state.page.events[index].text!;
  }

  void _editEvent(String newEventText) {
    final cubit = BlocProvider.of<EventScreenCubit>(context);
    cubit.editEvent(newEventText);
    _hideKeyboard();
    cubit.toggleSelected();
    cubit.setIsEditing();
  }

  void _addToFavorites() {
    final cubit = BlocProvider.of<EventScreenCubit>(context);
    final selectedEvents =
        cubit.state.page.events.where((element) => element.isSelected);
    _favoriteEvents.addAll(selectedEvents);
    cubit.toggleAllSelected();
    setState(() {});
    _favoriteEvents.forEach(print);
  }

  void _showKeyboard() {
    _inputNode.requestFocus();
  }

  void _hideKeyboard() {
    _inputNode.unfocus();
  }
}
