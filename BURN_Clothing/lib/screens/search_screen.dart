import 'package:flutter/material.dart';
import '../config/ui_helpers.dart';
import '../models/item.dart';
import '../services/store_service.dart';
import 'screens.dart';

class BurnSearch extends SearchDelegate<Item?> { @override List<Widget> buildActions(BuildContext context)=>[IconButton(icon:const Icon(Icons.clear),onPressed:()=>query='')];@override Widget buildLeading(BuildContext context)=>IconButton(icon:const Icon(Icons.arrow_back),onPressed:()=>close(context,null));@override Widget buildResults(BuildContext context)=>buildSuggestions(context);@override Widget buildSuggestions(BuildContext context)=>ListView(children:store.items.where((p)=>p.name.toLowerCase().contains(query.toLowerCase())).map((p)=>ListTile(title:Text(p.name),subtitle:Text(peso(p.price)),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductPage(item:p))))).toList());}
