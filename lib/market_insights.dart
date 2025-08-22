import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rss_dart/domain/rss_feed.dart';
import 'package:rss_dart/domain/rss_item.dart';

class MarketInsightsScreen extends StatefulWidget {
  @override
  _MarketInsightsScreenState createState() => _MarketInsightsScreenState();
}

class _MarketInsightsScreenState extends State<MarketInsightsScreen> {
  List<RssItem> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMarketNews();
  }

  Future<List<RssItem>> fetchMarketNews() async {
    final response =
        await http.get(Uri.parse("https://www.investing.com/rss/news_25.rss"));
    final feed = RssFeed.parse(response.body);
    return feed.items ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Color(0xFF1D1E33),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        title: Text(
          "Market Insights",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFEB1555)),
              ),
            )
          : RefreshIndicator(
              backgroundColor: Color(0xFF1D1E33),
              color: Color(0xFFEB1555),
              onRefresh: fetchMarketNews,
              child: ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: _articles.length,
                itemBuilder: (context, index) {
                  final article = _articles[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1D1E33),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        article.title ?? "No title",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        article.pubDate?.toString() ?? "",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFFEB1555),
                        size: 18,
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Color(0xFF1D1E33),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              article.title ?? "",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Text(
                                article.description ??
                                    "No description available.",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Close",
                                  style: TextStyle(color: Color(0xFFEB1555)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
