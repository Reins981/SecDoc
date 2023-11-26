// news_section.dart
import 'package:flutter/material.dart';
import 'package:church_silz/news_card.dart';
import 'package:church_silz/detailed_news.dart';
import 'package:google_fonts/google_fonts.dart';
import 'text_contents.dart';

class NewsSection extends StatefulWidget {

  const NewsSection({super.key, required this.selectedLanguage});

  final String selectedLanguage;

  @override
  _NewsSectionState createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {

  late List<NewsItem> newsItems;

  // Mock news data
  @override
  void initState() {
    super.initState();
    newsItems = [
      NewsItem(
        id: "1",
        imageUrl: 'assets/news1.jpg',
        date: "10.03.2023",
        selectedLanguage: widget.selectedLanguage,
      ),
      NewsItem(
        id: "2",
        imageUrl: 'assets/news2.jpg',
        date: "04.06.2021",
        selectedLanguage: widget.selectedLanguage,
      ),
      // Add more news items as needed
    ];
  }

  int selectedNewsIndex = 0;

  @override
  Widget build(BuildContext context) {

    final String newsMessageHeader = widget.selectedLanguage == "Deutsch" ?
    getTextContentGerman("newsMessageHeader"): getTextContentEnglish("newsMessageHeader");

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(newsMessageHeader, style: GoogleFonts.lato(fontSize: 20, letterSpacing: 1.0)),
        centerTitle: true,
        backgroundColor: const Color(0xFFD2B48C),
      ),
      body: SingleChildScrollView (
        child: Column(
          children: [
            const SizedBox(height: 20),
            NewsSlider(
              newsItems: newsItems,
              onNewsSelected: (index) {
                setState(() {
                  selectedNewsIndex = index;
                });
              },
              selectedNewsIndex: selectedNewsIndex,
            ),
            const SizedBox(height: 20),
            if (selectedNewsIndex < newsItems.length)
              DetailedNewsPage(newsItem: newsItems[selectedNewsIndex]),
          ],
        ),
      ),
    );
  }
}

class NewsItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String date;
  final String selectedLanguage;

  NewsItem({
    required this.id,
    required this.imageUrl,
    required this.date,
    required this.selectedLanguage,
  }): title = selectedLanguage == "Deutsch"
      ? getTextContentGerman("newsTitle_$id")
      : getTextContentEnglish("newsTitle_$id"),
        description = selectedLanguage == "Deutsch"
            ? getTextContentGerman("newsDescription_$id")
            : getTextContentEnglish("newsDescription_$id");

}

class NewsSlider extends StatelessWidget {
  final List<NewsItem> newsItems;
  final Function(int) onNewsSelected;
  final int selectedNewsIndex;

  NewsSlider({required this.newsItems, required this.onNewsSelected, required this.selectedNewsIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: newsItems.length,
        controller: PageController(
          initialPage: selectedNewsIndex,
          viewportFraction: (newsItems.length > 2) ? 0.5: 0.9,
        ),
        onPageChanged: onNewsSelected,
        itemBuilder: (context, index) {
          return NewsCard(
            newsItem: newsItems[index],
          );
        },
      ),
    );
  }
}

