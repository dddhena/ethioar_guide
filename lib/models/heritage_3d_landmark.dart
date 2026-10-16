class Hotspot3D {
  final String id;
  final String title;
  final String description;
  final String audioScript;
  final double x; // Normalized 3D position X (-1.0 to 1.0)
  final double y; // Normalized 3D position Y (-1.0 to 1.0)
  final double z; // Normalized 3D position Z (-1.0 to 1.0)

  const Hotspot3D({
    required this.id,
    required this.title,
    required this.description,
    required this.audioScript,
    required this.x,
    required this.y,
    required this.z,
  });
}

class Heritage3DLandmark {
  final String id;
  final String name;
  final String amharicName;
  final String period;
  final String location;
  final String description;
  final String architecturalStyle;
  final String significance;
  final String glbModelUrl;
  final String thumbnailUrl;
  final String ancientReconstructionNote;
  final String modernPreservationNote;
  final List<Hotspot3D> hotspots;
  final String virtualGuideWelcome;

  const Heritage3DLandmark({
    required this.id,
    required this.name,
    required this.amharicName,
    required this.period,
    required this.location,
    required this.description,
    required this.architecturalStyle,
    required this.significance,
    required this.glbModelUrl,
    required this.thumbnailUrl,
    required this.ancientReconstructionNote,
    required this.modernPreservationNote,
    required this.hotspots,
    required this.virtualGuideWelcome,
  });

  static const List<Heritage3DLandmark> sampleHeritageModels = [
    Heritage3DLandmark(
      id: 'lalibela-bete-giyorgis',
      name: 'Church of St. George (Bete Giyorgis)',
      amharicName: 'ቤተ ጊዮርጊስ',
      period: 'Late 12th – Early 13th Century',
      location: 'Lalibela, Amhara Region',
      description:
          'Carved from a single block of red volcanic tuff into the shape of a Greek cross, Bete Giyorgis is widely considered the eighth wonder of the world. Standing 12 meters deep in a carved trench.',
      architecturalStyle: 'Monolithic Rock-Hewn Greek Cross',
      significance: 'UNESCO World Heritage Site since 1978. Pilgrimage center for Ethiopian Orthodox Christians.',
      glbModelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      thumbnailUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=800&q=80',
      ancientReconstructionNote:
          'Originally accessed through an intricate network of ceremonial trenches and acoustic subterranean catacombs, carved entirely with picks, chisels, and divine faith without a single brick or mortar.',
      modernPreservationNote:
          'Protected under UNESCO continuous seismic and drainage monitoring. The natural drainage system still diverts rainwater away from the central sanctuary.',
      virtualGuideWelcome:
          'Selam! Welcome to Bete Giyorgis. I am Selam, your AR cultural guide. Behold the cruciform roof carved straight into the bedrock below your feet. Tap the glowing markers to uncover its 800-year-old architectural secrets.',
      hotspots: [
        Hotspot3D(
          id: 'roof-cross',
          title: 'Concentric Greek Cross Roof',
          description:
              'The roof features three nested relief carvings of equilateral Greek crosses, symbolizing the Holy Trinity and acting as a complex rain catchment system.',
          audioScript:
              'Notice the three nested crosses carved on the roof. They are not merely ornamental—master builders engineered subtle gradients to prevent rainwater pooling on the soft volcanic rock.',
          x: 0.0,
          y: 0.8,
          z: 0.0,
        ),
        Hotspot3D(
          id: 'rock-trench',
          title: 'Subterranean Carved Trench',
          description:
              'A 12-meter-deep bedrock perimeter isolate the church entirely from the surrounding hillside. Access is solely via narrow subterranean tunnels.',
          audioScript:
              'The church does not rise into the sky; instead, builders carved twelve meters straight into the mountain floor, leaving the church standing isolated within a massive chasm.',
          x: -0.65,
          y: -0.4,
          z: 0.3,
        ),
        Hotspot3D(
          id: 'ogive-windows',
          title: 'Aksumite Bracket Windows',
          description:
              'The upper tier windows demonstrate classical Aksumite architectural influence with stone frames imitating ancient wood-and-mortar masonry.',
          audioScript:
              'Look at these window frames. While carved in the 12th century, their stepped frames mirror the wooden beam architecture of the pre-Christian Kingdom of Aksum.',
          x: 0.5,
          y: 0.2,
          z: -0.4,
        ),
      ],
    ),
    Heritage3DLandmark(
      id: 'axum-obelisk',
      name: 'Obelisk of Axum (King Ezana Stele)',
      amharicName: 'የአክሱም ሐውልት',
      period: '4th Century AD',
      location: 'Axum, Tigray Region',
      description:
          'A 24-meter-tall monolithic granite stele weighing 160 tonnes. It portrays a ten-storey high-rise building with false doors, decorative beam ends, and an arched apex representing cosmic celestial spheres.',
      architecturalStyle: 'Aksumite Monolithic Granodiorite',
      significance: 'Apex of ancient African stone engineering. Returned from Rome to Ethiopia in 2005.',
      glbModelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      thumbnailUrl: 'https://images.unsplash.com/photo-1587974925564-afea072b4b87?auto=format&fit=crop&w=800&q=80',
      ancientReconstructionNote:
          'Erected over royal underground tomb chambers, originally inlaid with bronze plaques and a gleaming golden disc reflecting morning sunlight across the ancient capital.',
      modernPreservationNote:
          'Following its historic return from Italy in 2005, the obelisk was re-erected using carbon fiber tension rods and modern seismic stabilizers.',
      virtualGuideWelcome:
          'Welcome to ancient Axum! Standing before you is a 160-tonne single block of solid granite. Tap the 3D markers to see how ancient stone sculptors created this monumental skyscraper 1,700 years ago.',
      hotspots: [
        Hotspot3D(
          id: 'stele-apex',
          title: 'Crescent & Sun Apex',
          description:
              'The rounded top originally held gilded metallic plates representing celestial deities before King Ezana converted Axum to Christianity in 330 AD.',
          audioScript:
              'At the peak sits a semicircular arch. In pre-Christian Axumite royal monuments, this top held a gleaming bronze sunburst symbol visible across the Tigray plateau.',
          x: 0.0,
          y: 0.9,
          z: 0.0,
        ),
        Hotspot3D(
          id: 'false-door',
          title: 'The Symbolic False Door',
          description:
              'At the base is an intricately sculpted false door complete with a carved stone lock and handle, intended as an ethereal portal for the departed royalty.',
          audioScript:
              'Notice the stone handle and bolt carved into the bottom false doorway. It was crafted as a symbolic spirit entrance for the ancient emperors buried beneath.',
          x: 0.0,
          y: -0.7,
          z: 0.2,
        ),
        Hotspot3D(
          id: 'monkey-heads',
          title: 'Carved Beam Ends (Monkey Heads)',
          description:
              'Protruding rounded stone pegs imitate the circular timber cross-beams used in traditional Aksumite timber-and-stone wall construction.',
          audioScript:
              'These rounded stone nubs are known as monkey heads. They reflect the timber supports that were historically slotted into traditional Ethiopian stonework.',
          x: 0.25,
          y: 0.1,
          z: 0.0,
        ),
      ],
    ),
    Heritage3DLandmark(
      id: 'fasil-ghebbi',
      name: 'Fasil Ghebbi Castle Fortress',
      amharicName: 'ፋሲል ግቢ',
      period: '17th Century (Emperor Fasilides)',
      location: 'Gondar, Amhara Region',
      description:
          'The Camelot of Africa. A 900-meter-long walled castle compound comprising palaces, churches, monasteries, and unique crenellated parapets blending Portuguese, Moorish, and Aksumite architectural traditions.',
      architecturalStyle: 'Gondarine Baroque Castle',
      significance: 'Seat of Ethiopian Emperors from 1636 until 1864. UNESCO World Heritage Site.',
      glbModelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      thumbnailUrl: 'https://images.unsplash.com/photo-1609137144813-7d8bfe2a0e44?auto=format&fit=crop&w=800&q=80',
      ancientReconstructionNote:
          'In the 1600s, this courtyard buzzed with royal courtiers, imperial guards on battlements, ceremonial lion cages, and vibrant banqueting halls adorned with Venetian glass mirrors.',
      modernPreservationNote:
          'Extensively restored by the Authority for Research and Conservation of Cultural Heritage (ARCCH) with lime mortar and indigenous brown sandstone.',
      virtualGuideWelcome:
          'Tenayistillign! Step inside Fasilides Castle in Gondar. Emperor Fasilides established this permanent capital in 1636, breaking centuries of nomadic imperial tented camps. Let us explore the imperial fortress.',
      hotspots: [
        Hotspot3D(
          id: 'domed-turrets',
          title: 'Domed Corner Turrets',
          description:
              'Four rounded corner towers with domed cupolas provided 360-degree defensive sightlines across the Gondar valley and Lake Tana approach roads.',
          audioScript:
              'The four corner watchtowers are crowned with Moorish-style stone cupolas. Archery guards were stationed here around the clock to safeguard the imperial treasury.',
          x: -0.6,
          y: 0.5,
          z: 0.4,
        ),
        Hotspot3D(
          id: 'battlements',
          title: 'Crenellated Parapets & Archways',
          description:
              'Distinctive stone crenellations along the roofline offered tactical defense while arched balconies served for imperial public proclamations.',
          audioScript:
              'From this central balcony, Emperor Fasilides addressed thousands of subjects gathered in the royal grounds during Epiphany and victory celebrations.',
          x: 0.0,
          y: 0.2,
          z: 0.5,
        ),
      ],
    ),
    Heritage3DLandmark(
      id: 'lucy-dinkenesh',
      name: 'Lucy (Dinkenesh - "You are Marvelous")',
      amharicName: 'ድንቅነሽ',
      period: '3.2 Million Years Ago',
      location: 'National Museum of Ethiopia, Addis Ababa',
      description:
          'Several hundred pieces of bone fossils representing 40% of the skeleton of a female of the hominin species Australopithecus afarensis. Discovered in 1974 at Hadar in the Awash Valley.',
      architecturalStyle: 'Paleoanthropological Fossil Remains',
      significance: 'Definitive proof of early bipedal locomotion (walking upright) among human ancestors.',
      glbModelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      thumbnailUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
      ancientReconstructionNote:
          '3.2 million years ago in the lush prehistoric Awash savanna, Lucy walked upright on two legs, combining small brain capacity with bipedal human-like hip and knee anatomy.',
      modernPreservationNote:
          'The authentic fossil rests safely in a specialized subterranean vault at the National Museum in Addis Ababa, while exact precision casts are exhibited worldwide.',
      virtualGuideWelcome:
          'Welcome to the cradle of humankind. Meet Lucy, known locally as Dinkenesh, meaning "You are marvelous". She stood approximately 1.1 meters tall and unlocked our understanding of human origins.',
      hotspots: [
        Hotspot3D(
          id: 'pelvis-bipedal',
          title: 'Bipedal Pelvis Structure',
          description:
              'The broad, bowl-shaped pelvis proves Lucy walked upright on two feet, revolutionizing theories on when early hominins began standing.',
          audioScript:
              'Examine the hip bone structure. Its short, curved shape is remarkably human-like, proving that our ancestors walked upright long before our brain sizes enlarged.',
          x: 0.0,
          y: -0.1,
          z: 0.1,
        ),
        Hotspot3D(
          id: 'skull-jaw',
          title: 'Cranium & Dental Arch',
          description:
              'The cranial capacity is roughly 400 cc, similar to a chimpanzee, with small canine teeth characteristic of early hominin divergence.',
          audioScript:
              'The jaw displays smaller canines than primates, indicating dietary shifts and social changes over three million years ago.',
          x: 0.0,
          y: 0.7,
          z: 0.15,
        ),
      ],
    ),
  ];
}
