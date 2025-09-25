"""Number guessing Game"""
import random;

walker GuessGame {
    has guess: int;

    can start with `root entry;
    can process_guess with turn entry;
}

node turn {
    has correct_number: int = random.randint(1, 10);
}

# Will run when in CLI mode
 with entry:__main__ {
    root spawn GuessGame(3);
    root spawn GuessGame(4);
    root spawn GuessGame(5);
    root spawn GuessGame(6);
}

impl GuessGame.start {
    if not [root --> (`?turn)] {
        next = root ++> turn(random.randint(1, 10));
    } else {
        next = [root --> (`?turn)];
    }
    visit next;
}

impl GuessGame.process_guess {
    if [-->] {
        visit [-->];
    } else {
        if self.guess < here.correct_number {
            print("Too high!");
            here ++> turn(here.correct_number);
        } elif self.guess > here.correct_number {
            print("Too low!");
            here ++> turn(here.correct_number);
        } else {
            print("Congratulations! You guessed correctly.");
            disengage;
        }
    }

}

# # Will run when in CLI mode (not in cloud)
#  with entry:__main__ {
#     root spawn GuessGame(3);
#     root spawn GuessGame(4);
#     root spawn GuessGame(5);
#     root spawn GuessGame(6);
# }
# impl turn.check {
#     guess = input("Guess a number between 1 and 10: ");
#     if guess.isdigit() {
#         visitor.process_guess(int(guess));
#     } else {
#         print("That's not a valid number! Try again.");
#     }
#     visit [-->];
# }

# impl GuessGame.start {
#     if not [root --> (`?turn)] {
#         next = root ++> turn();
#     } else {
#         next = [root --> (`?turn)];
#     }
#     visit next;
# }

# impl GuessGame.process_guess(guess: int) {
#     if [-->] {
#         visit [-->];
#     } else {
#         if guess < self.correct_number {
#             print("Too low!");
#             here ++> turn();
#         } elif guess > self.correct_number {
#             print("Too high!");
#             here ++> turn();
#         } else {
#             print("Congratulations! You guessed correctly.");
#             disengage;
#         }
#     }
# }