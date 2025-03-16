import 'package:flutter/material.dart';

class StarRatingFormField extends FormField<int> {
  StarRatingFormField({
    Key? key,
    int initialValue = 0,
    FormFieldSetter<int>? onSaved,
    FormFieldValidator<int>? validator,
    ValueChanged<int>? onChanged,
  }) : super(
    key: key,
    initialValue: initialValue,
    onSaved: onSaved,
    validator: validator,
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
              updateRating(index + 1); // Update rating based on clicked star
            },
          );
        }),
      );
    },
  );
}