import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget quickAction(IconData icon, String title) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 35,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget destination(String place, String emoji) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          "$emoji\n\n$place",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "👋 Good Morning",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Harshu",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                decoration: InputDecoration(
                  hintText: "Search destination...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Upcoming Trip",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff1565C0),
                      Color(0xff42A5F5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),

                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "🏖 Goa",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      "12 Dec - 18 Dec",
                      style: TextStyle(color: Colors.white),
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Budget : ₹20,000",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [

                  quickAction(Icons.card_travel, "Trips"),

                  quickAction(Icons.account_balance_wallet, "Budget"),

                ],
              ),

              Row(
                children: [

                  quickAction(Icons.map, "Maps"),

                  quickAction(Icons.cloud, "Weather"),

                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Popular Destinations",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 140,

                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [

                    destination("Goa", "🏖"),

                    destination("Manali", "🏔"),

                    destination("Kashmir", "❄"),

                    destination("Bali", "🌴"),

                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}