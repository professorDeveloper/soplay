import 'package:flutter/material.dart';

class HomeViewAllPage extends StatefulWidget {
  final String keyCat;
  final String? slug;

  const HomeViewAllPage({super.key, this.slug = "", required this.keyCat});

  @override
  State<HomeViewAllPage> createState() => _HomeViewAllPageState();
}

class _HomeViewAllPageState extends State<HomeViewAllPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
