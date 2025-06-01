import 'package:flutter/material.dart';

class StarRatingFormField extends FormField<int> {
  StarRatingFormField({
    super.key,
    super.onSaved,
    super.validator,
    int initialValue = 0,
    ValueChanged<int>? onChanged,
  }) : super(
          initialValue: initialValue,
          builder: (FormFieldState<int> state) {
            void updateRating(int rating) {
              state.didChange(rating);
              if (onChanged != null) {
                onChanged(rating);
              }
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < state.value! ? Icons.star : Icons.star_border,
                    color: Colors.blue.shade600,
                  ),
                  onPressed: () {
                    updateRating(
                        index + 1); // Update rating based on clicked star
                  },
                );
              }),
            );
          },
        );
}
