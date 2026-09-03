import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tagnar_merchant/controller/auth_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final AuthController authController = Get.put(AuthController());

  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF0B1F4D);
  static const Color primary = Color(0xFF1D4ED8);
  static const Color blue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color background = Color(0xFFF7F9FC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Column(
                children: [
                  // ========================================================
                  // HERO
                  // ========================================================
                  _buildHero(),

                  const SizedBox(height: 26),

                  // ========================================================
                  // HEADLINE
                  // ========================================================
                  const Text(
                    "Grow Smarter.\nBuild Better.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Everything you need to manage your business, connect with customers, and grow with Ragnar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ========================================================
                  // FEATURES
                  // ========================================================
                  _buildFeatureGrid(),

                  const SizedBox(height: 28),

                  // ========================================================
                  // GOOGLE BUTTON
                  // ========================================================
                  _buildGoogleButton(),

                  const SizedBox(height: 13),

                  // ========================================================
                  // SECURITY
                  // ========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Secure sign-in powered by Google",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      height: 285,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [navy, Color(0xFF123A8C), blue],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // ============================================================
            // BACKGROUND DECORATIONS
            // ============================================================
            Positioned(
              right: -55,
              top: -65,
              child: _circle(180, Colors.white.withValues(alpha: 0.06)),
            ),

            Positioned(
              right: 40,
              top: 75,
              child: _circle(35, Colors.white.withValues(alpha: 0.05)),
            ),

            Positioned(
              left: -60,
              bottom: -70,
              child: _circle(170, Colors.white.withValues(alpha: 0.05)),
            ),

            Positioned(
              left: 30,
              top: 90,
              child: _circle(18, Colors.white.withValues(alpha: 0.07)),
            ),

            // ============================================================
            // CONTENT
            // ============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Column(
                children: [
                  // ========================================================
                  // TOP BRAND
                  // ========================================================
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: primary,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 11),

                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tagnar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          SizedBox(height: 1),

                          Text(
                            "Connect • Manage • Grow",
                            style: TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ========================================================
                  // CENTER ICON
                  // ========================================================
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          size: 34,
                          color: primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Your Business.\nYour Growth.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const Spacer(),

                  // ========================================================
                  // STATS
                  // ========================================================
                  Row(
                    children: [
                      Expanded(child: _heroStat("Easy", "Management")),

                      _statDivider(),

                      Expanded(child: _heroStat("Smart", "Insights")),

                      _statDivider(),

                      Expanded(child: _heroStat("Fast", "Growth")),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CIRCLE DECORATION
  // ============================================================

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ============================================================
  // HERO STAT
  // ============================================================

  Widget _heroStat(String value, String title) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STAT DIVIDER
  // ============================================================

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // ============================================================
  // FEATURES
  // ============================================================

  Widget _buildFeatureGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _featureCard(
                Icons.storefront_rounded,
                "Business",
                "Manage your business",
              ),

              const SizedBox(height: 12),

              _featureCard(
                Icons.people_alt_rounded,
                "Customers",
                "Connect with customers",
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            children: [
              _featureCard(
                Icons.insights_rounded,
                "Analytics",
                "Track your performance",
              ),

              const SizedBox(height: 12),

              _featureCard(
                Icons.rocket_launch_rounded,
                "Growth",
                "Grow your business",
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FEATURE CARD
  // ============================================================

  Widget _featureCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: primary),
          ),

          const SizedBox(height: 11),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              color: textDark,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GOOGLE SIGN-IN
  // ============================================================

  Widget _buildGoogleButton() {
    return Obx(() {
      if (authController.isLoading.value) {
        return Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Center(
            child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: primary,
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: () async {
            await authController.signInWithGoogle();
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shadowColor: primary.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Image.asset(
                  "assets/images/google.png",
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.g_mobiledata_rounded,
                      color: Colors.red,
                      size: 22,
                    );
                  },
                ),
              ),

              const SizedBox(width: 13),

              const Text(
                "Continue with Google",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),

              const SizedBox(width: 10),

              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      );
    });
  }
}
