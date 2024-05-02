import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

var API_KEY = "43666085-de5b5df00651987d2fab9dffe";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixabay Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PixabayGallery(),
    );
  }
}

class PixabayGallery extends StatefulWidget {
  @override
  _PixabayGalleryState createState() => _PixabayGalleryState();
}

class _PixabayGalleryState extends State<PixabayGallery> {
  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _images = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadMoreImages(); // Load initial images
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreImages();
    }
  }

  void _loadMoreImages() async {
    setState(() {
      _loading = true;
    });
    final response = await http.get(Uri.parse(
        'https://pixabay.com/api/?key=$API_KEY&page=${_images.length ~/ 30 + 1}&per_page=30'));

    if (response.statusCode == 200) {
      setState(() {
        _images.addAll(List<Map<String, dynamic>>.from(
            json.decode(response.body)['hits']));
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
      throw Exception('Failed to load images');
    }
  }

  void _searchImages(String query) async {
    if (query.isNotEmpty) {
      final response = await http
          .get(Uri.parse('https://pixabay.com/api/?key=$API_KEY&q=$query'));
      if (response.statusCode == 200) {
        setState(() {
          _images = List<Map<String, dynamic>>.from(
              json.decode(response.body)['hits']);
        });
      } else {
        throw Exception('Failed to search images');
      }
    } else {
      _loadMoreImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: (value) {
            _searchImages(value);
          },
          decoration: InputDecoration(
            hintText: 'Search images...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        controller: _scrollController,
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width ~/ 200,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: _images.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionsBuilder:
                        (context, animation, secondAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    pageBuilder: (context, animation, secondAnimation) {
                      return FullScreenImage(
                        imageUrl: _images[index]['largeImageURL'],
                      );
                    },
                    transitionDuration: Duration(milliseconds: 500),
                  ),
                );
              },
              child: Hero(
                tag: 'image$index',
                child: Image.network(
                  _images[index]['webformatURL'],
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
