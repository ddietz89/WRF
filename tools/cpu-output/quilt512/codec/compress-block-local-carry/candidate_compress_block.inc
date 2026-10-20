#if !defined(ZLIB_DEBUG) && BYTE_ORDER == LITTLE_ENDIAN && CHAR_BIT == 8
/* Private block-local carry; original emitters and other users are unchanged. */
static inline void zng_carry_emit_lit(deflate_state *s, const ct_data *ltree,
    unsigned c, uint64_t *bi_buf, uint32_t *bi_valid) {
    const uint32_t code_len = zng_emit_code_len_snapshot(&ltree[c]);
    send_bits(s, (uint16_t)code_len, code_len >> 16, *bi_buf, *bi_valid);
    Tracecv(isgraph(c & 0xff), (stderr, " '%c' ", c));
    Z_UNUSED(s);
}

static inline void zng_carry_emit_dist(deflate_state *s, const ct_data *ltree,
    const ct_data *dtree, uint32_t lc, uint32_t dist,
    uint64_t *bi_buf, uint32_t *bi_valid) {
    uint32_t c, extra;
    uint8_t code;
    uint64_t match_bits;
    uint32_t match_bits_len;

    code = zng_length_code[lc];
    c = code+LITERALS+1;
    Assert(c < L_CODES, "bad l_code");
    send_code_trace(s, c);

    {
        const uint32_t length_code_len = zng_emit_code_len_snapshot(&ltree[c]);
        match_bits = (uint16_t)length_code_len;
        match_bits_len = length_code_len >> 16;
    }
    extra = extra_lbits[code];
    if (extra != 0) {
        lc -= base_length[code];
        match_bits |= ((uint64_t)lc << match_bits_len);
        match_bits_len += extra;
    }

    dist--;
    code = d_code(dist);
    Assert(code < D_CODES, "bad d_code");
    send_code_trace(s, code);

    {
        const uint32_t distance_code_len = zng_emit_code_len_snapshot(&dtree[code]);
        match_bits |= ((uint64_t)(uint16_t)distance_code_len << match_bits_len);
        match_bits_len += distance_code_len >> 16;
    }
    extra = extra_dbits[code];
    if (extra != 0) {
        dist -= base_dist[code];
        match_bits |= ((uint64_t)dist << match_bits_len);
        match_bits_len += extra;
    }

    send_bits(s, match_bits, match_bits_len, *bi_buf, *bi_valid);
}

static inline void zng_carry_emit_end_block(deflate_state *s, const ct_data *ltree,
    uint64_t *bi_buf, uint32_t *bi_valid) {
    const uint32_t code_len = zng_emit_code_len_snapshot(&ltree[END_BLOCK]);
    send_bits(s, (uint16_t)code_len, code_len >> 16, *bi_buf, *bi_valid);
    Z_UNUSED(s);
}

static void compress_block(deflate_state *s, const ct_data *ltree, const ct_data *dtree) {
    /* ltree: literal tree */
    /* dtree: distance tree */
    unsigned dist;      /* distance of matched string */
    int lc;             /* match length or unmatched char (if dist == 0) */
    unsigned sx = 0;    /* running index in symbol buffers */

    /* Local pointers to avoid indirection */
    const unsigned int sym_next = s->sym_next;
#ifdef LIT_MEM
    uint16_t *d_buf = s->d_buf;
    unsigned char *l_buf = s->l_buf;
#else
    unsigned char *sym_buf = s->sym_buf;
#endif

    uint64_t bi_buf = s->bi_buf;
    uint32_t bi_valid = s->bi_valid;

    if (sym_next != 0) {
        do {
#ifdef LIT_MEM
            dist = d_buf[sx];
            lc = l_buf[sx++];
#else
            dist = sym_buf[sx++] & 0xff;
            dist += (unsigned)(sym_buf[sx++] & 0xff) << 8;
            lc = sym_buf[sx++];
#endif
            if (dist == 0) {
                zng_carry_emit_lit(s, ltree, lc, &bi_buf, &bi_valid);
            } else {
                zng_carry_emit_dist(s, ltree, dtree, lc, dist, &bi_buf, &bi_valid);
            } /* literal or match pair ? */

            /* Check for no overlay of pending_buf on needed symbols */
#ifdef LIT_MEM
            Assert(s->pending < 2 * (s->lit_bufsize + sx), "pending_buf overflow");
#else
            Assert(s->pending < s->lit_bufsize + sx, "pending_buf overflow");
#endif
        } while (sx < sym_next);
    }

    zng_carry_emit_end_block(s, ltree, &bi_buf, &bi_valid);
    s->bi_valid = bi_valid;
    s->bi_buf = bi_buf;
}
#else
static void compress_block(deflate_state *s, const ct_data *ltree, const ct_data *dtree) {
    /* ltree: literal tree */
    /* dtree: distance tree */
    unsigned dist;      /* distance of matched string */
    int lc;             /* match length or unmatched char (if dist == 0) */
    unsigned sx = 0;    /* running index in symbol buffers */

    /* Local pointers to avoid indirection */
    const unsigned int sym_next = s->sym_next;
#ifdef LIT_MEM
    uint16_t *d_buf = s->d_buf;
    unsigned char *l_buf = s->l_buf;
#else
    unsigned char *sym_buf = s->sym_buf;
#endif

    if (sym_next != 0) {
        do {
#ifdef LIT_MEM
            dist = d_buf[sx];
            lc = l_buf[sx++];
#else
            dist = sym_buf[sx++] & 0xff;
            dist += (unsigned)(sym_buf[sx++] & 0xff) << 8;
            lc = sym_buf[sx++];
#endif
            if (dist == 0) {
                zng_emit_lit(s, ltree, lc);
            } else {
                zng_emit_dist(s, ltree, dtree, lc, dist);
            } /* literal or match pair ? */

            /* Check for no overlay of pending_buf on needed symbols */
#ifdef LIT_MEM
            Assert(s->pending < 2 * (s->lit_bufsize + sx), "pending_buf overflow");
#else
            Assert(s->pending < s->lit_bufsize + sx, "pending_buf overflow");
#endif
        } while (sx < sym_next);
    }

    zng_emit_end_block(s, ltree, 0);
}
#endif
