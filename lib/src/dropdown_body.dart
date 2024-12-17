part of '../magic_dropdown_search.dart';


@immutable
class DropDownSearchBody extends StatefulWidget {
  final int itemsCount;
  final String? initValue;

  final ValueChanged<String?>? onChanged;
  final double? dropdownHeight;
  final double? itemHeight;
  final List<String> dropdownItems;
  final Future<List<String>> Function(String) onChangedSearch;
  final bool isCanNotSelect;
  final String notSelectedText;
  final Widget? empty;
  final InputDecoration? searchDecoration;
  final Widget Function(String, bool)? itemBuilder;

  const DropDownSearchBody({
    super.key,
    required this.itemsCount,
    this.searchDecoration,
    this.initValue,
    this.onChanged,
    this.dropdownHeight,
    this.itemHeight,
    required this.dropdownItems,
    required this.onChangedSearch,
    this.isCanNotSelect = false,
    this.notSelectedText = '--Bitte wählen--',
    this.empty,
    this.itemBuilder,
  });

  @override
  State<DropDownSearchBody> createState() => _DropDownSearchBodyState();
}

class _DropDownSearchBodyState extends State<DropDownSearchBody> {
  late String? value;
  late TextEditingController _searchController;
  String searchQuery = '';
  bool isSearching = false;
  bool isDisposed = false;
  ValueNotifier<List<String>> searchItemsNotifier = ValueNotifier<List<String>>([]);
  Completer<void>? _searchCompleter;

  @override
  void initState() {
    super.initState();
    _initValue();
    _searchController = TextEditingController();
    onChangSearch('');
  }

  @override
  void dispose() {
    isDisposed = true;
    _searchCompleter?.complete();
    _searchCompleter = null;
    _searchController.dispose();
    super.dispose();
  }

  void _initValue() {
    value = widget.initValue;
    searchItemsNotifier.value = widget.dropdownItems;
    if (widget.isCanNotSelect) {
      searchItemsNotifier.value = [
        widget.notSelectedText,
        ...widget.dropdownItems,
      ];
    }
  }

  Future<void> onChangSearch(String value) async {
    try {
      searchQuery = value;
      isSearching = true;
      setState(() {});

      _searchCompleter?.complete();
      _searchCompleter = Completer<void>();

      final results = await widget.onChangedSearch(value);
      if (_searchCompleter!.isCompleted || isDisposed) return;

      searchItemsNotifier.value = results;
      if (widget.isCanNotSelect) {
        searchItemsNotifier.value = [
          widget.notSelectedText,
          ...searchItemsNotifier.value,
        ];
      }
    } catch (e, s) {
      debugPrint('Error on search: $e $s');
    } finally {
      if (!isDisposed) {
        isSearching = false;
        setState(() {});
      }
    }
  }

  Future<void> onClearSearch() async {
    await onChangSearch('');
    _searchController.clear();
  }

  void onChanged(String? v) {
    value = v;
    if (v == widget.notSelectedText) {
      widget.onChanged?.call("");
    } else {
      widget.onChanged?.call(v);
    }
    setState(() {});
  }

  bool get _checkIsEmptyList {
    return searchItemsNotifier.value.isEmpty ||
        (searchItemsNotifier.value.length == 1 &&
            searchItemsNotifier.value[0] == widget.notSelectedText);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.dropdownHeight ?? 350,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.itemsCount > 10)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Text(
                  "إبحث من ضمن ${widget.itemsCount} عنصر ",
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          _buildSearchField(),
          const SizedBox(height: 10),
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: searchItemsNotifier,
              builder: (context, items, child) {
                if (isSearching) return _loading();
                if (_checkIsEmptyList) return _emptyList();
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == value;
                    return InkWell(
                      onTap: () {
                        onChanged(isSelected ? null : item);
                        Navigator.pop(context, item);
                      },
                      child: widget.itemBuilder != null
                          ? widget.itemBuilder!(item, isSelected)
                          : _buildListItem(item, isSelected),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.only(top: 5),
      child: TextFormField(
        onChanged: onChangSearch,
        controller: _searchController,
        decoration: widget.searchDecoration ??
            InputDecoration(
              hintText: 'Search...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
      ),
    );
  }

  Widget _buildListItem(String item, bool isSelected) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (isSelected) ...[
            const Icon(Icons.check, size: 16, color: Colors.black),
            const SizedBox(width: 7.5),
          ],
          Expanded(
            child: Text(
              item,
              maxLines: 3,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(vertical: 5),
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return Container(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            height: 50,
          );
        },
      ),
    );
  }

  Widget _emptyList() {
    if (widget.empty != null) {
      return widget.empty!;
    }
    return const Center(
      child: Text('No items found'),
    );
  }
}



