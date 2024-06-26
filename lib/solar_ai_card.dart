import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpandableCard extends StatefulWidget {
  final String titleText;
  final String bodyText;

  const ExpandableCard({
    required this.titleText,
    required this.bodyText,
    Key? key,
  }) : super(key: key);

  @override
  _ExpandableCardState createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _showCard = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ExpansionPanelList(
        elevation: 1,
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            _showCard = !_showCard;
          });
        },
        children: [
          ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                title: Text(
                  widget.titleText,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              );
            },
            body: Container(
              padding: EdgeInsets.all(16.0),
              child: Text(
                widget.bodyText,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            isExpanded: _showCard,
          ),
        ],
      ),
    );
  }
}
