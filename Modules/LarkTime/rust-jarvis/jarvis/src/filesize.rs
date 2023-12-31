use std::cmp::Ordering;
use std::cmp::Ordering::*;

const UNIT_SCALE: f64 = 1024.0;

#[derive(Copy, Clone)]
pub enum FileSize {
    B(f64),
    KB(f64),
    MB(f64),
    GB(f64),
}

impl FileSize {

    pub fn to_b(&self) -> FileSize {
        return match self {
            FileSize::B(b) => { FileSize::B(b * 1.0) },
            FileSize::KB(kb) => { FileSize::B(kb * UNIT_SCALE) },
            FileSize::MB(mb) => { FileSize::B(mb * UNIT_SCALE * UNIT_SCALE) },
            FileSize::GB(gb) => { FileSize::B(gb * UNIT_SCALE * UNIT_SCALE * UNIT_SCALE) },
        }
    }

    pub fn to_prefer_size(&self) -> FileSize {
        let to_b = self.to_b();
        return if let FileSize::B(byte) = to_b {
            let mut result: FileSize = FileSize::B(byte);
            let mut cal_size = byte;
            if cal_size > UNIT_SCALE {
                result = FileSize::KB(cal_size / UNIT_SCALE);
                cal_size = cal_size / UNIT_SCALE;
            }
            if cal_size > UNIT_SCALE {
                result = FileSize::MB(cal_size / UNIT_SCALE);
                cal_size = cal_size / UNIT_SCALE;
            }
            if cal_size > UNIT_SCALE {
                result = FileSize::GB(cal_size / UNIT_SCALE);
                cal_size = cal_size / UNIT_SCALE;
            }
            result
        } else {
            // default
            to_b
        }
    }

    pub fn size_to_print(&self) -> String {
        let prefer_size = self.to_prefer_size();
        match prefer_size {
            FileSize::B(b) => { format!("{0:.4} B", b) },
            FileSize::KB(kb) => { format!("{0:.4} kB", kb) },
            FileSize::MB(mb) => { format!("{0:.4} MB", mb) },
            FileSize::GB(gb) => { format!("{0:.4} GB", gb) }
        }
    }

    pub fn sort(&self, other: &FileSize) -> Ordering {
        let to_b_a = self.to_b();
        let to_b_b = other.to_b();
        if let FileSize::B(a_byte) = to_b_a {
            if let FileSize::B(b_byte) = to_b_b {
                return
                    if a_byte > b_byte { Greater }
                    else if a_byte < b_byte { Less }
                    else { Equal }
            }
        }
        unreachable!("could not compare different type filesize");
        return Equal;
    }

}