package fr.trill.covoit;

import fr.trill.covoit.model.AppUser;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
public class AppUserTest {

    @Mock
    AppUser user = new AppUser();

    @BeforeEach
    void setUp() {
        user.setFirstName("Marc");
        user.setLastName("Dutrain");
        user.setEmail("marc.dutrain@somemail.com");
        user.setEmailVerified(true);
        user.setPasswordHash("c6uz78j6jd786iz4dijzf5hi3zhf");
        user.setPhotoUrl("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSSZFl299Ls3IxqJVb_4HxEbfeT5tY2DXpAx9A2yX5t8w&s=10");
        user.setBio("employé d'une petite société");
    }

    @AfterEach
    void tearDown() {
        user = null;
    }
}
