package accessingData;

public class User {
    private String name;
    private String last_name;
    private String photo;
    private String biography;

    public User(String name, String last_name, String photo, String biography) {
        this.name = name;
        this.last_name = last_name;
        this.photo = photo;
        this.biography = biography;
    }

    public String getName() {
        return this.name;
    }

    public String getLastName() {
        return this.last_name;
    }
    public String getPhoto() {
        return this.photo;
    }

    public String getBiography() {
        return this.biography;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setLastName(String last_name) {
        this.last_name = last_name;
    }

    public void setPhoto(String photo) {
        this.photo = photo;
    }

    public void setBiography(String biography) {
        this.biography = biography;
    }
}
