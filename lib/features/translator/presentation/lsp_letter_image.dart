import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

class LspLetterImage extends StatelessWidget {
  final String letter;
  final double size;
  final String? customImagePath;

  const LspLetterImage({
    super.key,
    required this.letter,
    this.size = 200,
    this.customImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final cleanLetter = letter.trim().toUpperCase();

    // Estado en transición, reposo o vacío
    if (cleanLetter.isEmpty || cleanLetter == '---' || cleanLetter == '—') {
      return Container(
        height: size + 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceLight, width: 1),
              ),
              child: const Icon(
                Icons.sign_language_outlined,
                size: 54,
                color: AppColors.textSecond,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ESPERANDO SEÑA',
              style: TextStyle(
                color: AppColors.textSecond,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Usa el guante para traducir',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecond,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final Set<String> standardAlphabet = {
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
    };

    // Si no está en el alfabeto, asumimos que es una palabra personalizada registrada
    if (!standardAlphabet.contains(cleanLetter)) {
      final bool hasCustomImage = customImagePath != null && (kIsWeb ? (customImagePath!.startsWith('http') || customImagePath!.startsWith('blob:')) : File(customImagePath!).existsSync());

      return Container(
        height: size + 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasCustomImage)
              Container(
                width: size - 30,
                height: size - 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLight, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb
                      ? Image.network(
                          customImagePath!,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(customImagePath!),
                          fit: BoxFit.cover,
                        ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 54,
                  color: AppColors.accent,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              cleanLetter,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasCustomImage ? 'Seña personalizada' : '¡Seña personalizada detectada!',
              style: const TextStyle(
                color: AppColors.textSecond,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Ruta de la imagen: assets/images/A.png ... assets/images/N_tilde.png para Ñ
    final String fileName = cleanLetter == 'Ñ' ? 'N_tilde' : cleanLetter;
    final String imagePath = 'assets/images/$fileName.png';

    return Container(
      height: size + 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SEÑA DETECTADA',
            style: TextStyle(
              color: AppColors.textSecond,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Muestra qué archivo falta si no existe aún
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecond, size: 44),
                          const SizedBox(height: 8),
                          Text(
                            'Falta: $fileName.png',
                            style: const TextStyle(
                              color: AppColors.textSecond,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Coloca la imagen en assets/images/',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecond, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
