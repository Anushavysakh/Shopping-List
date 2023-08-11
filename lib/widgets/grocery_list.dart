import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shoppinglist_project/categories.dart';

import '../data/grocery_item.dart';
import 'new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  String? _error;
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    // TODO: implement initState
    _loadedItems = _loadItems();
    super.initState();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'shoppinglist-81505-default-rtdb.firebaseio.com', 'shopping-list.json');

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch data, Try again later');
      // setState(() {
      //   _error = 'Failed to load data, try after some time!';
      // });
    }
    if (response.body == null) {
      return [];
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    print(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere((categoryItem) =>
              categoryItem.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    return loadedItems;
  }

  void _addItem() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (context) => NewItem(),
    ));
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  Future<void> _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('shoppinglist-81505-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Groceries"), actions: [
        IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
      ]),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if(snapshot.data!.isEmpty){
            return const Center(
              child: Text('No Items added yet'),
            );

          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => Dismissible(
              key: ValueKey(snapshot.data![index].id),
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
              },
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(snapshot.data![index].quantity.toString()),
              ),
            ),
          );
        },
      ),
    );
  }
}
