# Photo Archive Pipeline

## High-Level Description

A photo archive stores personal photos.

Users browse their collections in different ways.

* Album view.
* Grid view.
* Search results.
* Full-size view.

Showing full-resolution photos everywhere would waste storage bandwidth and slow the user interface.

Instead, the system stores two versions of every uploaded photo.

* The original photo.
* A small thumbnail.

The original photo is used for viewing and downloading.

The thumbnail is used for fast browsing and preview.

Whenever a user uploads a new photo, the system automatically creates the thumbnail and stores both files.

---

# Software Requirements

The system accepts photo uploads from clients.

Each connection uploads one JPEG photo.

For every uploaded photo the system shall:

1. Receive the JPEG file.
2. Uncompress the JPEG into an image.
3. Create a thumbnail image.
4. Compress the thumbnail as JPEG.
5. Save the original JPEG file.
6. Save the thumbnail JPEG file.
7. Reply to the client.

The original upload is preserved.

Only the thumbnail is generated.

One uploaded photo produces two stored files.

---

# Architectural View

The previous section described **what** the system does.

Now we divide the work into independent responsibilities.

```
Receive Photo

        |

        V

Uncompress JPEG

        |

        V

Create Thumbnail

        |

        V

Compress Thumbnail

        |

        V

Store Files

        |

        V

Reply
```

Each responsibility performs one task.

Each responsibility receives its input.

Each responsibility produces its output.

The output of one stage becomes the input of the next stage.

---

# Matryoshka Translation

Each responsibility becomes a Master.

The uploaded photo becomes an Item.

The Item moves from one Master to the next.

```
+------------------+
| Receive Master   |
+------------------+
          |
          V
+------------------+
| Decode Master    |
+------------------+
          |
          V
+--------------------+
| Thumbnail Master   |
+--------------------+
          |
          V
+------------------+
| Encode Master    |
+------------------+
          |
          V
+------------------+
| Storage Master   |
+------------------+
          |
          V
+------------------+
| Reply Master     |
+------------------+
```

Each Master owns the Item while it performs its work.

When finished, ownership moves to the next Master.

No two Masters process the same Item at the same time.

---

# Flow

The client uploads one JPEG photo.

The Receive Master accepts the upload.

It forwards the photo to the Decode Master.

The Decode Master uncompresses the JPEG into an image.

It transfers the image to the Thumbnail Master.

The Thumbnail Master creates a smaller version of the image.

It forwards both the original image and the thumbnail image.

The Encode Master compresses the thumbnail into JPEG.

The original JPEG upload is preserved.

The Storage Master saves:

* the original JPEG file.
* the thumbnail JPEG file.

After both files are stored, the Reply Master sends a successful response to the client.

The request is complete.

---

# Why This Example

The example is intentionally simple.

It contains a linear processing pipeline.

Each stage has one responsibility.

Each stage has a clear input and output.

The reader can focus on the architecture rather than the image-processing algorithms.

The same architectural pattern applies to many other systems, including video processing, document conversion, data transformation, and network protocols.


# PNG is better choice


The goal of the document is to explain **Matryoshka-Io**, not JPEG support in Zig. If readers see "JPEG," some Zig developers may immediately think:

> "Wait, Zig std doesn't support JPEG."

That distracts from the architectural lesson.

Using **PNG + zstbi** avoids that issue because it's a common combination in the Zig ecosystem.

The story becomes:

* Client uploads a PNG image.
* The system reads the PNG.
* The system uncompresses it into pixels.
* The system creates a thumbnail.
* The system compresses the thumbnail as PNG.
* The system stores:

    * the original PNG
    * the thumbnail PNG


In architecture section:

> The system uncompresses the PNG image into pixels.

Then, in an implementation section or code example:

> This implementation uses `zstbi` to read and write PNG images.

