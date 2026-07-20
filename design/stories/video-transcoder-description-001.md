# Video Transcoder

## Flow description

The system accepts a video stream in one input format.

It converts the video into another output format.

The converted video preserves the original content.

The system reads the input video.

It extracts the video content into a form that can be processed.

The video content may be processed:
- adjust colors
- resize the image
- add a watermark
- perform other transformations

The processed content is converted into the requested output format.

The output video is stored.

# One Stream

This part describes processing of a single video stream.

Only one stream exists.

Parallel processing of multiple streams is introduced later.

---

# Participants

The system consists of the following participants.

## Input

Provides the source video stream.

Commands:

* Open stream
* Read data
* Close stream

Produces:

* Encoded video data

---

## Demuxer

Reads the input container.

Separates the video stream from other data.

Commands:

* Read encoded video data
* Extract video packets

Consumes:

* Encoded video data

Produces:

* Encoded video packets

---

## Decoder

Converts encoded video packets into images.

Commands:

* Decode packet
* Flush decoder

Consumes:

* Encoded video packets

Produces:

* Raw images

---

## Image Processor

Applies optional image transformations.

Commands:

* Process image

Consumes:

* Raw images

Produces:

* Processed images

Possible operations:

* Resize
* Crop
* Rotate
* Adjust colors
* Add watermark
* Other image transformations

---

## Encoder

Converts processed images into the requested output format.

Commands:

* Encode image
* Flush encoder

Consumes:

* Processed images

Produces:

* Encoded video packets

---

## Muxer

Builds the output video stream.

Commands:

* Write packet
* Finalize output

Consumes:

* Encoded video packets

Produces:

* Output video stream

---

## Output

Stores the converted video.

Commands:

* Write data
* Close stream

Consumes:

* Output video stream

---

# Flow

```
Input
    │
    V
Encoded video stream
    │
    V
Demuxer
    │
    V
Encoded video packets
    │
    V
Decoder
    │
    V
Raw images
    │
    V
Image Processor
    │
    V
Processed images
    │
    V
Encoder
    │
    V
Encoded video packets
    │
    V
Muxer
    │
    V
Output video stream
    │
    V
Output
```

---

# Notes

* One participant performs one responsibility.
* Data always moves forward.
* Each participant receives one kind of data and produces another.
* Commands control participant behavior.
* Mailboxes, Pools, and execution are intentionally omitted. They are introduced in the next stage.

---

