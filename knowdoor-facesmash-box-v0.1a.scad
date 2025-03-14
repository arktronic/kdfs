module kdfs_holes () {
    rotate([180, 0, 0]) color("red") translate([0, -40, -1]) linear_extrude(3) text("KD/FS", font="Impact:style=Regular", size=10, halign="center", $fn=100);
    rotate([180, 0, 0]) color("red") translate([0, -50, -1]) linear_extrude(3) text("v0.1", size=5, halign="center", $fn=100);
    
    // 12.28mm dia
    color("red") translate([0, -42, -5]) cylinder(h=10, r=6.2, $fn=100);
    color("blue") translate([0, -42, 1]) cylinder(h=3, r=9, $fn=100);
    
    color("red") translate([0, 0, 0]) cube([21.3, 21.3, 20], center = true);
    color("blue") translate([0, 0, 3]) cube([26, 26, 3], center = true);
}
//kdfs_holes();
color("green") translate([64, 0, 3]) cube([40, 90, 6], center = true);


// ARK modified from https://github.com/kumichou/lidded-box-with-honeycomb-grip

// Parameterized box generator
// Originally written by Brad Koehn
// Heavily modified by Eric Hankinson to include honeycomb grid on lid, and flatten groove to prevent pushout of box walls.
// Requires OpenSCAD 2014.03 or newer

// box dimensions in millimeters
// typically you want the height < width < length
box_width = 60; // x axis
box_length = 110;  // y axis
box_height = 40; // z axis

// thickness of all walls and lid
wall_width = 3;

// how far from the top of the box the lid notch should go
notch_height = 6;

// how deep into the wall the lid notch should go
notch_depth = wall_width / 2;

// diameter of button on lid; Set to 0 for no button
button_diameter = 0;

// height of button on lid
button_height = wall_width / 2;

// how thick walls of the honeycomb are
honeycomb_wall_thickness = 2;

// how thick/deep the honeycomb is; Set to 0 for no honeycomb
// alternatively, you can calculate the height based on the
// notch_height so the honeycomb is no taller than the top of the box
honeycomb_depth = 0;
//honeycomb_depth = notch_height - wall_width * 1.5;

// diameter of each honeycomb
honeycomb_diameter = 10;

// width of the honeycomb pattern
honeycomb_width = box_width - (wall_width * 4);

// length of the honeycomb pattern
honeycomb_length = box_length - (wall_width * 4);


/*
If you need extra strength in the walls
*/

// length & width of the wall support column
wall_support_width = 0;

// calculate the height of the column to be right underneath the lid track
wall_support_height = box_height - (notch_depth + (2 * wall_width));

/*
If you want a sliding divider that splits the length of the box internally
*/
divider_wall = 0;
//divider_wall = wall_width;

/*
The lid, slightly smaller than the slot in the box. The inset will give just enough that printing
will either require no trimming or little sanding to get the lid to slide easily in the box.
*/

difference () {
union () {
    translate([0, 0, box_height / 2])
        difference () {
            // our solid box
            cube([box_width, box_length, box_height], center = true);

            // remove the inside
            translate([0, 0, wall_width / 2])
                cube([box_width - wall_width * 2, box_length - wall_width * 2, box_height - wall_width], center = true);

            // remove notch for lid
            translate([0, 0, box_height / 2 - notch_height / 2])
                lid();

            // remove the unnecessary part of box where the lid slides in
            translate([0, wall_width / 2, box_height / 2 ])
                cube([box_width - wall_width * 2, box_length - wall_width, notch_height], center = true);
        };

    if (wall_support_width > 0) {
        translate([- (.5 * (box_width - (4 * wall_width))), 0, (.5 * wall_support_height) + wall_width]) {
            cube([wall_width * 2, wall_width * 2, wall_support_height], center = true);
        }

        translate([(.5 * (box_width - (4 * wall_width))), 0, (.5 * wall_support_height) + wall_width]) {
            cube([wall_width * 2, wall_width * 2, wall_support_height], center = true);
        }
    }
    
    if (divider_wall > 0) {
        difference () {
            union() {
                translate([- (.5 * (box_width - (2.5 * wall_width))), 0, (.5 * wall_support_height) + wall_width]) {
                    cube([wall_width / 2, wall_width * 3, wall_support_height], center = true);
                }

                translate([(.5 * (box_width - (2.5 * wall_width))), 0, (.5 * wall_support_height) + wall_width]) {
                    cube([wall_width / 2, wall_width * 3, wall_support_height], center = true);
                }
            }
            
            translate([0, 0, (.5 * wall_support_height + wall_width)]) {
                cube([box_width, wall_width + 1, wall_support_height], center = true);
            }
        }
    }
};
kdfs_holes();
};


translate([box_width + 4, 0, wall_width / 2]) {
    lid(0.25);
};

if (divider_wall > 0) {
    translate([0, .75 * box_length, .5 * wall_width]) {
        cube([box_width - (wall_width * 2) - 1, wall_support_height, wall_width - .5], center = true);
    }
}

module walledDivider() {
    
}

module divider(thickness = 0, width = 0, height = 0) {
    
}

module lid(inset = 0) {
    union() {
        polyhedron(
            points = [
                // top points, clockwise starting at max x, max y
                [box_width / 2 - wall_width - inset, box_length / 2, notch_depth], // 0
                [box_width / 2 - wall_width - inset, -(box_length / 2 - wall_width), notch_depth], // 1
                [-(box_width / 2 - wall_width + inset), -(box_length / 2 - wall_width), notch_depth], // 2
                [-(box_width / 2 - wall_width + inset), box_length / 2, notch_depth], // 3

                // middle points, clockwise starting at max x, max y
                [box_width / 2 - wall_width + notch_depth - inset, box_length / 2, -notch_depth], // 4
                [box_width / 2 - wall_width + notch_depth - inset, -(box_length / 2 - wall_width + notch_depth), -notch_depth], // 5
                [-(box_width / 2 - wall_width  + notch_depth + inset), -(box_length / 2 - wall_width + notch_depth), -notch_depth], // 6
                [-(box_width / 2 - wall_width  + notch_depth + inset), box_length / 2, -notch_depth], // 7

                // bottom points, clockwise starting at max x, max y
                [box_width / 2 - wall_width - inset, box_length / 2, -notch_depth], // 8
                [box_width / 2 - wall_width - inset, -(box_length / 2 - wall_width), -notch_depth], // 9
                [-(box_width / 2 - wall_width + inset), -(box_length / 2 - wall_width), -notch_depth], // 10
                [-(box_width / 2 - wall_width + inset), box_length / 2, -notch_depth], // 11
            ],
            faces = [
                [0, 1, 2, 3], // top face

                [0, 4, 5, 1], // left top notch
                [1, 5, 6, 2], // back top notch
                [3, 2, 6, 7], // right top notch

                [4, 8, 9, 5], // left bottom notch
                [5, 9, 10, 6], // back botton notch
                [7, 6, 10, 11], // right bottom notch

                [11, 10, 9, 8], // bottom face

                [0, 3, 7, 11, 8, 4] // front face
            ]
        );

        if (button_diameter > 0) {
            translate([0, box_length / 2 - button_diameter, wall_width / 2]) {
                cylinder(
                    d = button_diameter,
                    h = button_height
                );
            };
        }

        if (honeycomb_depth > 0) {
            translate([-((.5 * honeycomb_width) + (wall_width / 6)), - ((.5 * honeycomb_length) - (wall_width / 2)), wall_width / 2]) {
                union() {
                    honeycomb(honeycomb_length, honeycomb_width, honeycomb_depth, honeycomb_diameter, honeycomb_wall_thickness);
                    
                    difference() {
                        translate([(.5 * honeycomb_width), (.5 * honeycomb_length), wall_width / 4]) {
                            cube([honeycomb_width, honeycomb_length + (honeycomb_wall_thickness * 2), honeycomb_depth], center = true);
                        };
                        
                        translate([(.5 * honeycomb_width), (.5 * honeycomb_length), wall_width / 4]) {
                            cube([honeycomb_width - (honeycomb_wall_thickness * 2), honeycomb_length , honeycomb_depth], center = true);
                        };
                    };
                };
            };
        }
    };
}

module hc_column(length, cell_size, wall_thickness) {
    no_of_cells = floor(length / (cell_size + wall_thickness)) ;

    for (i = [0 : no_of_cells]) {
        translate([0, (i * (cell_size + wall_thickness)), 0]) {
            circle($fn = 6, r = cell_size * (sqrt(3)/3));
        }
    }
}

module honeycomb (width, length, height, cell_size, wall_thickness) {
    no_of_rows = floor(1.2 * length / (cell_size + wall_thickness));

    tr_mod = cell_size + wall_thickness;
    tr_x = sqrt(3)/2 * tr_mod;
    tr_y = tr_mod / 2;
    off_x = -1 * wall_thickness / 2;
    off_y = wall_thickness / 2;

    linear_extrude(height = height, convexity = 10, twist = 0, slices = 1)
    {
        difference() {
            square([length, width]);
            for (i = [0 : no_of_rows]) {
                translate([i * tr_x + off_x, (i % 2) * tr_y + off_y,0])
                hc_column(width, cell_size, wall_thickness);
            }
        };
    };
}

