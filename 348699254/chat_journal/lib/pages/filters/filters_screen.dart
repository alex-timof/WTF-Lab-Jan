import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants.dart';
import '../search_filter.dart';
import 'filters_cubit.dart';
import 'filters_state.dart';

class FiltersScreen extends StatefulWidget {
  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen>
    with TickerProviderStateMixin {
  final _searchInputController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    BlocProvider.of<FiltersCubit>(context).showActivityPages();
    BlocProvider.of<FiltersCubit>(context).showCategoryList();
    BlocProvider.of<FiltersCubit>(context).hashTagList();
    _searchInputController.addListener(() {
      if (_searchInputController.text.isNotEmpty) {
        BlocProvider.of<FiltersCubit>(context).startSearching();
      } else {
        BlocProvider.of<FiltersCubit>(context).finishSearching();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FiltersCubit, FiltersState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Align(
              child: Text('Filters'),
              alignment: Alignment.center,
            ),
          ),
          body: _bodyStructure(state),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              BlocProvider.of<FiltersCubit>(context).clearAllSelectedLists();
              if (state.searchData.isNotEmpty) {
                Navigator.pop(context, [
                  SearchFilter.search,
                  state.searchData,
                ]);
              } else if (state.selectedPageList.isNotEmpty) {
                Navigator.pop(context, [
                  SearchFilter.page,
                  state.selectedPageList,
                  state.arePagesIgnored,
                ]);
              } else if (state.selectedHashtagList.isNotEmpty) {
                Navigator.pop(context, [
                  SearchFilter.tag,
                  state.selectedHashtagList,
                ]);
              } else if (state.selectedCategoryList.isNotEmpty) {
                Navigator.pop(context, [
                  SearchFilter.category,
                  state.selectedCategoryList,
                ]);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Icon(Icons.check),
          ),
        );
      },
    );
  }

  Widget _bodyStructure(FiltersState state) {
    return Column(
      children: <Widget>[
        _textFormFieldForSearching(state),
        Expanded(
          child: _tabBar(state),
        ),
      ],
    );
  }

  Widget _textFormFieldForSearching(FiltersState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 5, 10, 5),
      child: TextFormField(
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.teal,
            size: 26,
          ),
          suffixIcon: state.isSearching
              ? IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  color: Colors.teal,
                  iconSize: 26,
                  onPressed: _searchInputController.clear,
                )
              : null,
          isDense: true,
          hintText: 'Search Query',
          fillColor: Colors.tealAccent,
          filled: true,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 18,
          ),
        ),
        keyboardType: TextInputType.text,
        controller: _searchInputController,
        onChanged: (text) =>
            BlocProvider.of<FiltersCubit>(context).searchEvent(text),
        onFieldSubmitted: (text) =>
            BlocProvider.of<FiltersCubit>(context).searchEvent(text),
      ),
    );
  }

  Widget _tabBar(FiltersState state) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          children: <Widget>[
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.amber,
              tabs: [
                Tab(
                  text: 'Pages',
                ),
                Tab(
                  text: 'Tags',
                ),
                Tab(
                  text: 'Labels',
                ),
                Tab(
                  text: 'Others',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _pagesTabContent(state),
                  _hashtagsTabContent(state),
                  _categoriesTabContent(state),
                  const Center(child: Text('Others')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pagesTabContent(FiltersState state) {
    final selectedPageIgnored =
        '${state.selectedPageList.length} page(s) Ignored';
    final selectedPageIncluded =
        '${state.selectedPageList.length} page(s) Included';
    return Column(
      children: [
        if (state.selectedPageList.isNotEmpty && state.arePagesIgnored)
          _startFilterContainer(selectedPageIgnored),
        if (state.selectedPageList.isNotEmpty && !state.arePagesIgnored)
          _startFilterContainer(selectedPageIncluded),
        if (state.selectedPageList.isEmpty) _startFilterContainer(pageText),
        Container(
          margin: const EdgeInsets.all(10),
          child: _ignoreSelectedPagesSwitch(state),
        ),
        _pageTagList(state),
      ],
    );
  }

  Widget _hashtagsTabContent(FiltersState state) {
    final selectedTagText =
        '${state.selectedHashtagList.length} tag(s) selected';
    return Column(
      children: [
        state.selectedHashtagList.isNotEmpty
            ? _startFilterContainer(selectedTagText)
            : _startFilterContainer(hashtagText),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.all(10),
          child: _hashtagList(state),
        ),
      ],
    );
  }

  Widget _categoriesTabContent(FiltersState state) {
    final selectedCategoriesText =
        '${state.selectedCategoryList.length} category(ies) selected';
    return Column(
      children: [
        state.selectedCategoryList.isNotEmpty
            ? _startFilterContainer(selectedCategoriesText)
            : _startFilterContainer(categoryText),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.all(10),
          child: _categoryTagList(state),
        ),
      ],
    );
  }

  Widget _startFilterContainer(String text) {
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.fromLTRB(25, 30, 25, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          decoration: BoxDecoration(
            color: Colors.greenAccent,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _ignoreSelectedPagesSwitch(FiltersState state) {
    return ListTile(
      title: const Text(
        'Ignore selected pages',
        style: TextStyle(fontSize: 16),
      ),
      subtitle:
          const Text('If enabled, the selected page(s)\nwon\'t be displayed'),
      trailing: Switch.adaptive(
        activeColor: Colors.amber,
        value: state.arePagesIgnored,
        onChanged: (value) =>
            BlocProvider.of<FiltersCubit>(context).arePagesIgnored(),
      ),
      onTap: () {},
    );
  }

  Widget _pageTagList(FiltersState state) {
    return Wrap(
      spacing: 10,
      children: <Widget>[
        for (var page in state.pageList)
          FilterChip(
            backgroundColor: Colors.deepPurpleAccent,
            selectedColor: Colors.purpleAccent,
            avatar: Icon(
              _iconData[page.iconIndex],
              color: Colors.black,
            ),
            label: Text(page.name),
            selected:
                BlocProvider.of<FiltersCubit>(context).isPageSelected(page),
            onSelected: (selected) =>
                BlocProvider.of<FiltersCubit>(context).onPageSelected(page),
          ),
      ],
    );
  }

  Widget _hashtagList(FiltersState state) {
    return Wrap(
      spacing: 10,
      children: <Widget>[
        for (var tag in state.hashtagList)
          FilterChip(
            backgroundColor: Colors.deepPurpleAccent,
            selectedColor: Colors.purpleAccent,
            label: Text(tag),
            selected:
                BlocProvider.of<FiltersCubit>(context).isHashtagSelected(tag),
            onSelected: (selected) =>
                BlocProvider.of<FiltersCubit>(context).onHashtagSelected(tag),
          ),
      ],
    );
  }

  Widget _categoryTagList(FiltersState state) {
    var entries = _categoriesMap.entries.toList();
    return Wrap(
      spacing: 10,
      children: <Widget>[
        for (int i = 0; i < state.categoryNameList.length; i++)
          FilterChip(
            backgroundColor: Colors.deepPurpleAccent,
            selectedColor: Colors.purpleAccent,
            avatar: Icon(
              entries.elementAt(state.categoryIconList[i]!).value,
              color: Colors.black,
              size: 20,
            ),
            label: Text(state.categoryNameList[i]!),
            selected: BlocProvider.of<FiltersCubit>(context)
                .isCategorySelected(state.categoryNameList[i]!),
            onSelected: (selected) => BlocProvider.of<FiltersCubit>(context)
                .onCategorySelected(state.categoryNameList[i]!),
          ),
      ],
    );
  }

  final Map<String, IconData> _categoriesMap = {
    'Cancel': Icons.cancel,
    'Workout': Icons.sports_tennis_rounded,
    'Movie': Icons.local_movies,
    'FastFood': Icons.fastfood,
    'Running': Icons.directions_run_outlined,
    'Sports': Icons.sports_baseball_rounded,
    'Laundry': Icons.local_laundry_service,
  };

  final List<IconData> _iconData = const [
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
    Icons.airplane_ticket,
    Icons.weekend,
    Icons.sports_baseball_sharp,
  ];
}
