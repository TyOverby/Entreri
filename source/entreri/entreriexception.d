module entreri.entreriexception;

class EntreriException: object.Error {
    this(string message) {
        super(message);
    }
}
